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
    std::ostream& out() { return out_; }
    bool is_eof() const { return in_.eof(); }

private:
    std::ostream& out_;
    std::istream& in_;
};

void print_str(const std::string& str);
void print_number(int32_t val);
void print_crlf();
void print_ok();

} // namespace pbasic
