#include <core/program.hpp>

namespace pbasic {

void Program::clear() {
    lines_.clear();
}

bool Program::empty() const {
    return lines_.empty();
}

bool Program::has_line(uint16_t line_no) const {
    return lines_.find(line_no) != lines_.end();
}

size_t Program::line_count() const {
    return lines_.size();
}

void Program::set_line(uint16_t line_no, std::vector<Token> tokens, std::string raw_text) {
    if (tokens.empty() || (tokens.size() == 1 && tokens[0].type == TokenType::EOL)) {
        lines_.erase(line_no);
        return;
    }
    lines_[line_no] = ProgramLine{line_no, std::move(tokens), std::move(raw_text)};
}

bool Program::remove_line(uint16_t line_no) {
    return lines_.erase(line_no) > 0;
}

const ProgramLine* Program::get_line(uint16_t line_no) const {
    auto it = lines_.find(line_no);
    if (it != lines_.end()) {
        return &it->second;
    }
    return nullptr;
}

const ProgramLine* Program::get_first_line() const {
    if (lines_.empty()) {
        return nullptr;
    }
    return &lines_.begin()->second;
}

const ProgramLine* Program::get_next_line(uint16_t current_line_no) const {
    auto it = lines_.upper_bound(current_line_no);
    if (it != lines_.end()) {
        return &it->second;
    }
    return nullptr;
}

void Program::list(std::ostream& out) const {
    for (const auto& [num, line] : lines_) {
        out << num << " " << detokenize(line.tokens) << '\n';
    }
}

size_t Program::byte_size() const {
    size_t total = 0;
    for (const auto& [num, line] : lines_) {
        total += 4 + detokenize(line.tokens).size() + 1;
    }
    return total;
}

} // namespace pbasic
