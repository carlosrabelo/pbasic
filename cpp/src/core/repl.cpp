#include <core/repl.hpp>
#include <core/signals.hpp>
#include <cctype>

namespace pbasic {

std::string trim(const std::string& str) {
    size_t start = 0;
    while (start < str.size() && std::isspace(static_cast<unsigned char>(str[start]))) {
        ++start;
    }
    size_t end = str.size();
    while (end > start && std::isspace(static_cast<unsigned char>(str[end - 1]))) {
        --end;
    }
    return str.substr(start, end - start);
}

ParsedLinePrefix classify_line(const std::string& line) {
    std::string trimmed = trim(line);
    if (trimmed.empty()) {
        return {LineType::Empty, 0, ""};
    }

    if (std::isdigit(static_cast<unsigned char>(trimmed[0]))) {
        size_t idx = 0;
        uint64_t num = 0;
        while (idx < trimmed.size() && std::isdigit(static_cast<unsigned char>(trimmed[idx]))) {
            num = num * 10 + (trimmed[idx] - '0');
            if (num > 65535) {
                break;
            }
            ++idx;
        }

        if (num >= 1 && num <= 65535) {
            std::string rest = trim(trimmed.substr(idx));
            return {LineType::Numbered, static_cast<uint16_t>(num), rest};
        }
    }

    return {LineType::Immediate, 0, trimmed};
}

void REPL::run() {
    while (true) {
        check_and_reset_interrupted();
        io_.print_str("> ");
        auto line_opt = io_.read_line();
        if (!line_opt.has_value()) {
            if (check_and_reset_interrupted()) {
                io_.print_crlf();
                continue;
            }
            if (io_.is_eof()) {
                io_.print_crlf();
                break;
            }
            io_.print_crlf();
            break;
        }

        std::string trimmed = trim(*line_opt);
        if (trimmed.empty()) {
            continue;
        }

        if (trimmed == "EXIT") {
            break;
        }

        auto prefix = classify_line(trimmed);
        if (prefix.type == LineType::Numbered) {
            if (numbered_handler_) {
                numbered_handler_(prefix.line_number, prefix.content);
            }
        } else if (prefix.type == LineType::Immediate) {
            if (immediate_handler_) {
                bool should_continue = immediate_handler_(prefix.content);
                if (!should_continue) {
                    break;
                }
            }
        }
    }
}

} // namespace pbasic
