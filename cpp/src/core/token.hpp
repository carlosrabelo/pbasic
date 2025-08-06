#pragma once

#include <cstdint>
#include <string>

namespace pbasic {

enum class TokenType {
    // Keywords
    KW_LET, KW_GOTO, KW_GOSUB, KW_PRINT, KW_IF, KW_INPUT,
    KW_RETURN, KW_END, KW_LIST, KW_RUN, KW_NEW, KW_EXIT,
    KW_REM, KW_THEN,

    // Built-in functions
    FN_FREE, FN_RND, FN_ABS,

    // Literals & Identifiers
    NUMBER,   // Holds int32_t
    STRING,   // Holds std::string
    VARIABLE, // Holds char 'A'..'Z'

    // Operators
    PLUS, MINUS, ASTERISK, SLASH,
    EQUAL, NOT_EQUAL, LESS, GREATER, LESS_EQUAL, GREATER_EQUAL,

    // Punctuation & Control
    LPAREN, RPAREN, COMMA, SEMICOLON,
    EOL, END_OF_INPUT, ILLEGAL
};

struct Token {
    TokenType type{TokenType::ILLEGAL};
    std::string text;
    int32_t number_value{0};
    char var_name{'\0'};

    bool operator==(const Token& other) const {
        return type == other.type &&
               text == other.text &&
               number_value == other.number_value &&
               var_name == other.var_name;
    }
};

const char* token_type_name(TokenType type);

} // namespace pbasic
