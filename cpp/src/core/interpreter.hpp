#pragma once

#include <core/evaluator.hpp>
#include <core/io.hpp>
#include <core/program.hpp>
#include <core/token.hpp>
#include <core/variables.hpp>
#include <cstdint>
#include <string>
#include <vector>

namespace pbasic {

enum class ExecResult {
    Ok,
    Stop,
    SyntaxError,
};

class Interpreter {
public:
    Interpreter(IO& io, Program& prog, VariableStore& vars, uint16_t rand_seed = 12345);

    ExecResult execute_statement(const std::vector<Token>& tokens);
    void execute_line(const std::string& line);
    ExecResult run_program();

    VariableStore& vars() { return vars_; }
    Program& program() { return prog_; }
    IO& io() { return io_; }
    bool exit_requested() const { return exit_requested_; }
    bool is_running() const { return is_running_; }
    void interrupt() { halted_ = true; }

private:
    ExecResult exec_print(const std::vector<Token>& tokens, size_t& cursor);
    ExecResult exec_let(const std::vector<Token>& tokens, size_t& cursor);
    ExecResult exec_input(const std::vector<Token>& tokens, size_t& cursor);
    ExecResult exec_new();
    ExecResult exec_free();
    ExecResult exec_goto(const std::vector<Token>& tokens, size_t& cursor);
    ExecResult exec_gosub(const std::vector<Token>& tokens, size_t& cursor);
    ExecResult exec_return();
    ExecResult exec_if(const std::vector<Token>& tokens, size_t& cursor);
    ExecResult exec_end();
    ExecResult exec_exit();
    ExecResult exec_list();
    void syntax_error();

    IO& io_;
    Program& prog_;
    VariableStore& vars_;
    uint16_t rand_seed_;

    std::vector<uint16_t> gosub_stack_;
    uint16_t current_line_no_{0};
    uint16_t branch_target_{0};
    bool branch_taken_{false};
    bool halted_{false};
    bool exit_requested_{false};
    bool is_running_{false};
};

} // namespace pbasic
