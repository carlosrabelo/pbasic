#include <core/io.hpp>

namespace pbasic {

static IO g_default_io(std::cout, std::cin);

std::string fold_case(const std::string& input) {
    std::string result;
    result.reserve(input.size());
    bool in_quotes = false;
    for (char ch : input) {
        if (ch == '"') {
            in_quotes = !in_quotes;
            result.push_back(ch);
        } else if (!in_quotes && ch >= 'a' && ch <= 'z') {
            result.push_back(static_cast<char>(ch - 'a' + 'A'));
        } else {
            result.push_back(ch);
        }
    }
    return result;
}

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

std::optional<std::string> IO::read_line() {
    std::string line;
    if (!std::getline(in_, line)) {
        if (!in_.eof()) {
            in_.clear();
        }
        return std::nullopt;
    }
    if (!line.empty() && line.back() == '\r') {
        line.pop_back();
    }
    return fold_case(line);
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

std::optional<std::string> read_line() {
    return g_default_io.read_line();
}

} // namespace pbasic
