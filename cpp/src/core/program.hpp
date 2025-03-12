#pragma once

#include <core/token.hpp>
#include <core/tokenizer.hpp>
#include <cstdint>
#include <map>
#include <ostream>
#include <string>
#include <vector>

namespace pbasic {

struct ProgramLine {
    uint16_t line_number{0};
    std::vector<Token> tokens;
    std::string raw_text;
};

class Program {
public:
    void clear();
    bool empty() const;
    bool has_line(uint16_t line_no) const;
    size_t line_count() const;

    void set_line(uint16_t line_no, std::vector<Token> tokens, std::string raw_text = "");
    bool remove_line(uint16_t line_no);

    const ProgramLine* get_line(uint16_t line_no) const;
    const ProgramLine* get_first_line() const;
    const ProgramLine* get_next_line(uint16_t current_line_no) const;

    void list(std::ostream& out) const;
    size_t byte_size() const;

private:
    std::map<uint16_t, ProgramLine> lines_;
};

} // namespace pbasic
