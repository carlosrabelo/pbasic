#pragma once

#include <core/io.hpp>
#include <cstdint>
#include <functional>
#include <string>

namespace pbasic {

enum class LineType {
    Empty,
    Numbered,
    Immediate,
};

struct ParsedLinePrefix {
    LineType type;
    uint16_t line_number;
    std::string content;
};

ParsedLinePrefix classify_line(const std::string& line);

class REPL {
public:
    explicit REPL(IO& io) : io_(io) {}

    void set_numbered_handler(std::function<void(uint16_t, const std::string&)> handler) {
        numbered_handler_ = std::move(handler);
    }

    void set_immediate_handler(std::function<bool(const std::string&)> handler) {
        immediate_handler_ = std::move(handler);
    }

    void run();

private:
    IO& io_;
    std::function<void(uint16_t, const std::string&)> numbered_handler_;
    std::function<bool(const std::string&)> immediate_handler_;
};

} // namespace pbasic
