#include <core/interpreter.hpp>
#include <core/signals.hpp>
#include <core/tokenizer.hpp>

namespace pbasic {

Interpreter::Interpreter(IO& io, Program& prog, VariableStore& vars, uint16_t rand_seed)
    : io_(io), prog_(prog), vars_(vars), rand_seed_(rand_seed) {}

void Interpreter::syntax_error() {
    io_.print_str("?SYNTAX ERROR\n");
}

void Interpreter::execute_line(const std::string& line) {
    Tokenizer tokenizer;
    auto tokens = tokenizer.tokenize(line);
    execute_statement(tokens);
}

ExecResult Interpreter::execute_statement(const std::vector<Token>& tokens) {
    if (tokens.empty()) {
        return ExecResult::Ok;
    }

    size_t cursor = 0;
    const auto& first = tokens[cursor];

    switch (first.type) {
        case TokenType::EOL:
        case TokenType::END_OF_INPUT:
            return ExecResult::Ok;

        case TokenType::KW_PRINT:
            ++cursor;
            return exec_print(tokens, cursor);

        case TokenType::KW_LET:
            ++cursor;
            return exec_let(tokens, cursor);

        case TokenType::KW_INPUT:
            ++cursor;
            return exec_input(tokens, cursor);

        case TokenType::VARIABLE:
            return exec_let(tokens, cursor);

        case TokenType::KW_NEW:
            return exec_new();

        case TokenType::KW_REM:
            return ExecResult::Ok;

        case TokenType::FN_FREE:
            return exec_free();

        case TokenType::KW_RUN:
            return run_program();

        case TokenType::KW_GOTO:
            ++cursor;
            return exec_goto(tokens, cursor);

        case TokenType::KW_GOSUB:
            ++cursor;
            return exec_gosub(tokens, cursor);

        case TokenType::KW_RETURN:
            return exec_return();

        case TokenType::KW_IF:
            ++cursor;
            return exec_if(tokens, cursor);

        case TokenType::KW_END:
            return exec_end();

        case TokenType::KW_EXIT:
            return exec_exit();

        case TokenType::KW_LIST:
            return exec_list();

        default:
            syntax_error();
            return ExecResult::SyntaxError;
    }
}

ExecResult Interpreter::run_program() {
    if (prog_.empty()) {
        io_.print_str("?NO PROGRAM\n");
        return ExecResult::Ok;
    }

    gosub_stack_.clear();
    halted_ = false;
    is_running_ = true;

    const ProgramLine* cur = prog_.get_first_line();

    while (cur != nullptr && !halted_ && !exit_requested_) {
        if (check_and_reset_interrupted()) {
            halted_ = true;
            io_.print_crlf();
            break;
        }

        current_line_no_ = cur->line_number;
        branch_taken_ = false;

        ExecResult res = execute_statement(cur->tokens);
        if (res == ExecResult::SyntaxError) {
            is_running_ = false;
            return res;
        }

        if (halted_ || exit_requested_) {
            break;
        }

        if (branch_taken_) {
            cur = prog_.get_line(branch_target_);
        } else {
            cur = prog_.get_next_line(current_line_no_);
        }
    }

    is_running_ = false;
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_goto(const std::vector<Token>& tokens, size_t& cursor) {
    Evaluator eval(tokens, vars_, prog_, rand_seed_);
    eval.set_cursor(cursor);
    int32_t target = eval.eval_expression();
    cursor = eval.get_cursor();

    if (target < 1 || target > 65535 || !prog_.has_line(static_cast<uint16_t>(target))) {
        syntax_error();
        halted_ = true;
        return ExecResult::SyntaxError;
    }

    branch_target_ = static_cast<uint16_t>(target);
    branch_taken_ = true;
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_gosub(const std::vector<Token>& tokens, size_t& cursor) {
    if (gosub_stack_.size() >= 16) {
        syntax_error();
        halted_ = true;
        return ExecResult::SyntaxError;
    }

    const auto* next = prog_.get_next_line(current_line_no_);
    gosub_stack_.push_back(next ? next->line_number : 0);

    return exec_goto(tokens, cursor);
}

ExecResult Interpreter::exec_return() {
    if (gosub_stack_.empty()) {
        syntax_error();
        halted_ = true;
        return ExecResult::SyntaxError;
    }

    uint16_t ret_line = gosub_stack_.back();
    gosub_stack_.pop_back();

    if (ret_line == 0) {
        halted_ = true;
        return ExecResult::Ok;
    }

    branch_target_ = ret_line;
    branch_taken_ = true;
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_if(const std::vector<Token>& tokens, size_t& cursor) {
    Evaluator eval(tokens, vars_, prog_, rand_seed_);
    eval.set_cursor(cursor);
    bool cond = eval.eval_condition();
    cursor = eval.get_cursor();

    if (cursor >= tokens.size() || tokens[cursor].type != TokenType::KW_THEN) {
        syntax_error();
        return ExecResult::SyntaxError;
    }
    ++cursor;

    if (!cond) {
        return ExecResult::Ok;
    }

    if (cursor < tokens.size() && tokens[cursor].type == TokenType::NUMBER) {
        uint16_t target = static_cast<uint16_t>(tokens[cursor].number_value);
        if (!prog_.has_line(target)) {
            syntax_error();
            halted_ = true;
            return ExecResult::SyntaxError;
        }
        branch_target_ = target;
        branch_taken_ = true;
        return ExecResult::Ok;
    }

    std::vector<Token> remaining(tokens.begin() + cursor, tokens.end());
    return execute_statement(remaining);
}

ExecResult Interpreter::exec_end() {
    halted_ = true;
    return ExecResult::Stop;
}

ExecResult Interpreter::exec_exit() {
    exit_requested_ = true;
    halted_ = true;
    return ExecResult::Stop;
}

ExecResult Interpreter::exec_list() {
    prog_.list(io_.out());
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_print(const std::vector<Token>& tokens, size_t& cursor) {
    bool trailing_semicolon = false;

    while (cursor < tokens.size()) {
        const auto& tok = tokens[cursor];

        if (tok.type == TokenType::EOL || tok.type == TokenType::END_OF_INPUT) {
            break;
        }

        if (tok.type == TokenType::STRING) {
            io_.print_str(tok.text);
            ++cursor;
            trailing_semicolon = false;
        } else if (tok.type == TokenType::COMMA) {
            io_.print_str("        ");
            ++cursor;
            trailing_semicolon = false;
        } else if (tok.type == TokenType::SEMICOLON) {
            ++cursor;
            trailing_semicolon = true;
        } else {
            Evaluator eval(tokens, vars_, prog_, rand_seed_);
            eval.set_cursor(cursor);
            int32_t val = eval.eval_expression();
            cursor = eval.get_cursor();
            io_.print_number(val);
            trailing_semicolon = false;
        }
    }

    if (!trailing_semicolon) {
        io_.print_crlf();
    }

    return ExecResult::Ok;
}

ExecResult Interpreter::exec_let(const std::vector<Token>& tokens, size_t& cursor) {
    if (cursor >= tokens.size() || tokens[cursor].type != TokenType::VARIABLE) {
        syntax_error();
        return ExecResult::SyntaxError;
    }

    char var_name = tokens[cursor].var_name;
    ++cursor;

    if (cursor >= tokens.size() || tokens[cursor].type != TokenType::EQUAL) {
        syntax_error();
        return ExecResult::SyntaxError;
    }
    ++cursor;

    Evaluator eval(tokens, vars_, prog_, rand_seed_);
    eval.set_cursor(cursor);
    int32_t val = eval.eval_expression();
    cursor = eval.get_cursor();

    vars_.set(var_name, val);
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_input(const std::vector<Token>& tokens, size_t& cursor) {
    if (cursor < tokens.size() && tokens[cursor].type == TokenType::STRING) {
        io_.print_str(tokens[cursor].text);
        ++cursor;
        if (cursor >= tokens.size() || tokens[cursor].type != TokenType::SEMICOLON) {
            syntax_error();
            return ExecResult::SyntaxError;
        }
        ++cursor;
    } else {
        io_.print_str("? ");
    }

    if (cursor >= tokens.size() || tokens[cursor].type != TokenType::VARIABLE) {
        syntax_error();
        return ExecResult::SyntaxError;
    }

    char var_name = tokens[cursor].var_name;
    ++cursor;

    auto line_opt = io_.read_line();
    if (check_and_reset_interrupted()) {
        io_.print_crlf();
        halted_ = true;
        return ExecResult::Stop;
    }
    if (!line_opt.has_value()) {
        halted_ = true;
        return ExecResult::Stop;
    }

    int32_t val = 0;
    std::string s = *line_opt;
    // Trim leading/trailing whitespace
    size_t start = 0;
    while (start < s.size() && std::isspace(static_cast<unsigned char>(s[start]))) ++start;
    size_t end = s.size();
    while (end > start && std::isspace(static_cast<unsigned char>(s[end - 1]))) --end;
    s = s.substr(start, end - start);

    if (!s.empty()) {
        try {
            val = std::stoi(s);
        } catch (...) {
            val = 0;
        }
    }

    vars_.set(var_name, val);
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_new() {
    prog_.clear();
    vars_.clear();
    io_.print_ok();
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_free() {
    size_t byte_size = prog_.byte_size();
    size_t free_bytes = (16384 >= byte_size) ? (16384 - byte_size) : 0;
    io_.print_number(static_cast<int32_t>(free_bytes));
    io_.print_crlf();
    return ExecResult::Ok;
}

} // namespace pbasic
