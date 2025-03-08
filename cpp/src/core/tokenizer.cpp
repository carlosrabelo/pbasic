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

        if (ch >= 'A' && ch <= 'Z') {
            advance();
            std::string ident;
            ident.push_back(ch);
            while (!is_at_end() && peek() >= 'A' && peek() <= 'Z') {
                ident.push_back(advance());
            }

            if (ident == "LET") {
                tokens.push_back({TokenType::KW_LET, ident, 0, '\0'});
            } else if (ident == "GOTO") {
                tokens.push_back({TokenType::KW_GOTO, ident, 0, '\0'});
            } else if (ident == "GOSUB") {
                tokens.push_back({TokenType::KW_GOSUB, ident, 0, '\0'});
            } else if (ident == "PRINT") {
                tokens.push_back({TokenType::KW_PRINT, ident, 0, '\0'});
            } else if (ident == "IF") {
                tokens.push_back({TokenType::KW_IF, ident, 0, '\0'});
            } else if (ident == "INPUT") {
                tokens.push_back({TokenType::KW_INPUT, ident, 0, '\0'});
            } else if (ident == "RETURN") {
                tokens.push_back({TokenType::KW_RETURN, ident, 0, '\0'});
            } else if (ident == "END") {
                tokens.push_back({TokenType::KW_END, ident, 0, '\0'});
            } else if (ident == "LIST") {
                tokens.push_back({TokenType::KW_LIST, ident, 0, '\0'});
            } else if (ident == "RUN") {
                tokens.push_back({TokenType::KW_RUN, ident, 0, '\0'});
            } else if (ident == "NEW") {
                tokens.push_back({TokenType::KW_NEW, ident, 0, '\0'});
            } else if (ident == "EXIT") {
                tokens.push_back({TokenType::KW_EXIT, ident, 0, '\0'});
            } else if (ident == "REM") {
                std::string comment = input_.substr(pos_);
                pos_ = input_.size();
                tokens.push_back({TokenType::KW_REM, comment, 0, '\0'});
            } else if (ident == "THEN") {
                tokens.push_back({TokenType::KW_THEN, ident, 0, '\0'});
            } else if (ident == "FREE") {
                tokens.push_back({TokenType::FN_FREE, ident, 0, '\0'});
            } else if (ident == "RND") {
                tokens.push_back({TokenType::FN_RND, ident, 0, '\0'});
            } else if (ident == "ABS") {
                tokens.push_back({TokenType::FN_ABS, ident, 0, '\0'});
            } else if (ident.size() == 1) {
                tokens.push_back({TokenType::VARIABLE, ident, 0, ident[0]});
            } else {
                tokens.push_back({TokenType::VARIABLE, std::string(1, ident[0]), 0, ident[0]});
                pos_ -= (ident.size() - 1);
            }
            continue;
        }

        ch = advance();

        if (ch >= '0' && ch <= '9') {
            std::string num_str;
            num_str.push_back(ch);
            int64_t val = (ch - '0');
            while (!is_at_end() && peek() >= '0' && peek() <= '9') {
                char digit = advance();
                num_str.push_back(digit);
                val = val * 10 + (digit - '0');
            }
            tokens.push_back({TokenType::NUMBER, num_str, static_cast<int32_t>(val), '\0'});
            continue;
        }

        if (ch == '"') {
            std::string str_content;
            while (!is_at_end() && peek() != '"') {
                str_content.push_back(advance());
            }
            if (!is_at_end() && peek() == '"') {
                advance();
            }
            tokens.push_back({TokenType::STRING, str_content, 0, '\0'});
            continue;
        }

        switch (ch) {
            case '+':
                tokens.push_back({TokenType::PLUS, "+", 0, '\0'});
                break;
            case '-':
                tokens.push_back({TokenType::MINUS, "-", 0, '\0'});
                break;
            case '*':
                tokens.push_back({TokenType::ASTERISK, "*", 0, '\0'});
                break;
            case '/':
                tokens.push_back({TokenType::SLASH, "/", 0, '\0'});
                break;
            case '(':
                tokens.push_back({TokenType::LPAREN, "(", 0, '\0'});
                break;
            case ')':
                tokens.push_back({TokenType::RPAREN, ")", 0, '\0'});
                break;
            case ',':
                tokens.push_back({TokenType::COMMA, ",", 0, '\0'});
                break;
            case ';':
                tokens.push_back({TokenType::SEMICOLON, ";", 0, '\0'});
                break;
            case '=':
                tokens.push_back({TokenType::EQUAL, "=", 0, '\0'});
                break;
            case '<':
                if (!is_at_end() && peek() == '>') {
                    advance();
                    tokens.push_back({TokenType::NOT_EQUAL, "<>", 0, '\0'});
                } else if (!is_at_end() && peek() == '=') {
                    advance();
                    tokens.push_back({TokenType::LESS_EQUAL, "<=", 0, '\0'});
                } else {
                    tokens.push_back({TokenType::LESS, "<", 0, '\0'});
                }
                break;
            case '>':
                if (!is_at_end() && peek() == '=') {
                    advance();
                    tokens.push_back({TokenType::GREATER_EQUAL, ">=", 0, '\0'});
                } else {
                    tokens.push_back({TokenType::GREATER, ">", 0, '\0'});
                }
                break;
            default:
                tokens.push_back({TokenType::ILLEGAL, std::string(1, ch), 0, '\0'});
                break;
        }
    }

    tokens.push_back({TokenType::EOL, "", 0, '\0'});
    return tokens;
}

} // namespace pbasic
