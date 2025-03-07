#include <core/tokenizer.hpp>
#include <cctype>

namespace pbasic {

void Tokenizer::skip_whitespace() {
    while (!is_at_end() && (input_[pos_] == ' ' || input_[pos_] == '\t')) {
        pos_++;
    }
}

char Tokenizer::peek() const {
    if (is_at_end()) return '\0';
    return input_[pos_];
}

char Tokenizer::advance() {
    return input_[pos_++];
}

bool Tokenizer::is_at_end() const {
    return pos_ >= input_.size();
}

std::vector<Token> Tokenizer::tokenize(const std::string& input) {
    input_ = input;
    pos_ = 0;
    std::vector<Token> tokens;

    while (!is_at_end()) {
        skip_whitespace();
        if (is_at_end()) break;

        char ch = peek();

        switch (ch) {
            case '+':
                advance();
                tokens.push_back({TokenType::PLUS, "+", 0, '\0'});
                break;
            case '-':
                advance();
                tokens.push_back({TokenType::MINUS, "-", 0, '\0'});
                break;
            case '*':
                advance();
                tokens.push_back({TokenType::ASTERISK, "*", 0, '\0'});
                break;
            case '/':
                advance();
                tokens.push_back({TokenType::SLASH, "/", 0, '\0'});
                break;
            case '(':
                advance();
                tokens.push_back({TokenType::LPAREN, "(", 0, '\0'});
                break;
            case ')':
                advance();
                tokens.push_back({TokenType::RPAREN, ")", 0, '\0'});
                break;
            case ',':
                advance();
                tokens.push_back({TokenType::COMMA, ",", 0, '\0'});
                break;
            case ';':
                advance();
                tokens.push_back({TokenType::SEMICOLON, ";", 0, '\0'});
                break;
            default:
                advance();
                tokens.push_back({TokenType::ILLEGAL, std::string(1, ch), 0, '\0'});
                break;
        }
    }

    tokens.push_back({TokenType::EOL, "", 0, '\0'});
    return tokens;
}

} // namespace pbasic
