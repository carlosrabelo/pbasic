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

} // namespace pbasic
