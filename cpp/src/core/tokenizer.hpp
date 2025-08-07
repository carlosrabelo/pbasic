#pragma once

#include <core/token.hpp>
#include <string>
#include <vector>

namespace pbasic {

class Tokenizer {
public:
    std::vector<Token> tokenize(const std::string& input);

private:
    void skip_whitespace();
    char peek() const;
    char advance();
    bool is_at_end() const;

    std::string input_;
    size_t pos_{0};
};

} // namespace pbasic
