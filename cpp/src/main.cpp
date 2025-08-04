#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc >= 2) {
        std::ifstream file(argv[1]);
        if (!file.is_open()) {
            std::cerr << "Cannot open file: " << argv[1] << '\n';
            return 1;
        }
        return 0;
    }

    std::cout << "PBasic\n";
    return 0;
}
