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

ExecResult Interpreter::exec_print(const std::vector<Token>&, size_t&) {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_let(const std::vector<Token>&, size_t&) {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_input(const std::vector<Token>&, size_t&) {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_new() {
    return ExecResult::Ok;
}

ExecResult Interpreter::exec_free() {
    return ExecResult::Ok;
}

} // namespace pbasic
