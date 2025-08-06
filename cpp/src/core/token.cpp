#include <core/token.hpp>

namespace pbasic {

const char* token_type_name(TokenType type) {
    switch (type) {
        case TokenType::KW_LET: return "LET";
        case TokenType::KW_GOTO: return "GOTO";
        case TokenType::KW_GOSUB: return "GOSUB";
        case TokenType::KW_PRINT: return "PRINT";
        case TokenType::KW_IF: return "IF";
        case TokenType::KW_INPUT: return "INPUT";
        case TokenType::KW_RETURN: return "RETURN";
        case TokenType::KW_END: return "END";
        case TokenType::KW_LIST: return "LIST";
        case TokenType::KW_RUN: return "RUN";
        case TokenType::KW_NEW: return "NEW";
        case TokenType::KW_EXIT: return "EXIT";
        case TokenType::KW_REM: return "REM";
        case TokenType::KW_THEN: return "THEN";
        case TokenType::FN_FREE: return "FREE";
        case TokenType::FN_RND: return "RND";
        case TokenType::FN_ABS: return "ABS";
        case TokenType::NUMBER: return "NUMBER";
        case TokenType::STRING: return "STRING";
        case TokenType::VARIABLE: return "VARIABLE";
        case TokenType::PLUS: return "+";
        case TokenType::MINUS: return "-";
        case TokenType::ASTERISK: return "*";
        case TokenType::SLASH: return "/";
        case TokenType::EQUAL: return "=";
        case TokenType::NOT_EQUAL: return "<>";
        case TokenType::LESS: return "<";
        case TokenType::GREATER: return ">";
        case TokenType::LESS_EQUAL: return "<=";
        case TokenType::GREATER_EQUAL: return ">=";
        case TokenType::LPAREN: return "(";
        case TokenType::RPAREN: return ")";
        case TokenType::COMMA: return ",";
        case TokenType::SEMICOLON: return ";";
        case TokenType::EOL: return "EOL";
        case TokenType::END_OF_INPUT: return "END_OF_INPUT";
        case TokenType::ILLEGAL: return "ILLEGAL";
    }
    return "UNKNOWN";
}

} // namespace pbasic
