#include <core/interpreter.hpp>
#include <core/io.hpp>
#include <core/program.hpp>
#include <core/repl.hpp>
#include <core/signals.hpp>
#include <core/tokenizer.hpp>
#include <core/variables.hpp>
#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    pbasic::install_signal_handlers();
    pbasic::IO io(std::cout, std::cin);
    pbasic::Program prog;
    pbasic::VariableStore vars;
    pbasic::Interpreter interp(io, prog, vars);
    pbasic::Tokenizer tokenizer;

    if (argc >= 2) {
        std::ifstream file(argv[1]);
        if (!file.is_open()) {
            std::cerr << "Cannot open file: " << argv[1] << '\n';
            return 1;
        }

        std::string raw_line;
        while (std::getline(file, raw_line)) {
            if (!raw_line.empty() && raw_line.back() == '\r') {
                raw_line.pop_back();
            }
            std::string folded = pbasic::fold_case(raw_line);
            auto prefix = pbasic::classify_line(folded);
            if (prefix.type == pbasic::LineType::Numbered) {
                prog.set_line(prefix.line_number, tokenizer.tokenize(prefix.content));
            } else if (prefix.type == pbasic::LineType::Immediate) {
                interp.execute_statement(tokenizer.tokenize(prefix.content));
            }
        }

        interp.run_program();
        return 0;
    }

    io.print_str("PBasic\n");
    pbasic::REPL repl(io);

    repl.set_numbered_handler([&](uint16_t num, const std::string& line) {
        prog.set_line(num, tokenizer.tokenize(line));
    });

    repl.set_immediate_handler([&](const std::string& line) {
        auto tokens = tokenizer.tokenize(line);
        interp.execute_statement(tokens);
        return !interp.exit_requested();
    });

    repl.run();
    return 0;
}
