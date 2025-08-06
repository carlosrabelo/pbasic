#include <core/io.hpp>
#include <core/repl.hpp>
#include <core/signals.hpp>
#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    pbasic::install_signal_handlers();
    pbasic::IO io(std::cout, std::cin);

    if (argc >= 2) {
        std::ifstream file(argv[1]);
        if (!file.is_open()) {
            std::cerr << "Cannot open file: " << argv[1] << '\n';
            return 1;
        }
        return 0;
    }

    io.print_str("PBasic\n");
    pbasic::REPL repl(io);
    repl.run();
    return 0;
}
