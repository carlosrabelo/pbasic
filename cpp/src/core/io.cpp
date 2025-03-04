#include <core/io.hpp>

namespace pbasic {

static IO g_default_io(std::cout, std::cin);

void IO::print_str(const std::string& str) {
    out_ << str;
}

void IO::print_number(int32_t val) {
    out_ << val;
}

void IO::print_crlf() {
    out_ << '\n';
}

void IO::print_ok() {
    out_ << "OK\n";
}

void print_str(const std::string& str) {
    g_default_io.print_str(str);
}

void print_number(int32_t val) {
    g_default_io.print_number(val);
}

void print_crlf() {
    g_default_io.print_crlf();
}

void print_ok() {
    g_default_io.print_ok();
}

} // namespace pbasic
