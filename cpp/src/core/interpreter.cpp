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
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_goto(const std::vector<Token>&, size_t&) {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_gosub(const std::vector<Token>&, size_t&) {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_return() {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_if(const std::vector<Token>&, size_t&) {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_end() {
    return ExecResult::Stop;
}

ExecResult Interpreter::exec_exit() {
    exit_requested_ = true;
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

ExecResult Interpreter::exec_input(const std::vector<Token>&, size_t&) {
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
