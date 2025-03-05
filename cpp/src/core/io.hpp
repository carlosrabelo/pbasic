#pragma once

#include <cstdint>
#include <iostream>
#include <optional>
#include <string>

namespace pbasic {

class IO {
public:
    explicit IO(std::ostream& out = std::cout, std::istream& in = std::cin)
        : out_(out), in_(in) {}

    void print_str(const std::string& str);
    void print_number(int32_t val);
    void print_crlf();
    void print_ok();
    std::optional<std::string> read_line();
    std::ostream& out() { return out_; }
    bool is_eof() const { return in_.eof(); }

private:
    std::ostream& out_;
    std::istream& in_;
};

std::string fold_case(const std::string& input);
void print_str(const std::string& str);
void print_number(int32_t val);
void print_crlf();
void print_ok();
std::optional<std::string> read_line();

} // namespace pbasic
