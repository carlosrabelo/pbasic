#include <catch.hpp>
#include <core/tokenizer.hpp>

TEST_CASE("Tokenizer scanning loop and punctuation", "[tokenizer]") {
    pbasic::Tokenizer tokenizer;

    SECTION("skips whitespace and produces EOL for empty input") {
        auto tokens = tokenizer.tokenize("   \t  ");
        REQUIRE(tokens.size() == 1);
        REQUIRE(tokens[0].type == pbasic::TokenType::EOL);
    }

    SECTION("scans punctuation and arithmetic operators") {
        auto tokens = tokenizer.tokenize("+ - * / ( ) , ;");
        REQUIRE(tokens.size() == 9);
        REQUIRE(tokens[0].type == pbasic::TokenType::PLUS);
        REQUIRE(tokens[1].type == pbasic::TokenType::MINUS);
        REQUIRE(tokens[2].type == pbasic::TokenType::ASTERISK);
        REQUIRE(tokens[3].type == pbasic::TokenType::SLASH);
        REQUIRE(tokens[4].type == pbasic::TokenType::LPAREN);
        REQUIRE(tokens[5].type == pbasic::TokenType::RPAREN);
        REQUIRE(tokens[6].type == pbasic::TokenType::COMMA);
        REQUIRE(tokens[7].type == pbasic::TokenType::SEMICOLON);
        REQUIRE(tokens[8].type == pbasic::TokenType::EOL);
    }

    SECTION("scans keywords, functions, and variables") {
        auto tokens = tokenizer.tokenize("LET A PRINT B IF C THEN GOTO GOSUB RETURN END LIST RUN NEW EXIT FREE RND ABS");
        REQUIRE(tokens[0].type == pbasic::TokenType::KW_LET);
        REQUIRE(tokens[1].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[1].var_name == 'A');
        REQUIRE(tokens[2].type == pbasic::TokenType::KW_PRINT);
        REQUIRE(tokens[3].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[3].var_name == 'B');
        REQUIRE(tokens[4].type == pbasic::TokenType::KW_IF);
        REQUIRE(tokens[5].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[5].var_name == 'C');
        REQUIRE(tokens[6].type == pbasic::TokenType::KW_THEN);
        REQUIRE(tokens[7].type == pbasic::TokenType::KW_GOTO);
        REQUIRE(tokens[8].type == pbasic::TokenType::KW_GOSUB);
        REQUIRE(tokens[9].type == pbasic::TokenType::KW_RETURN);
        REQUIRE(tokens[10].type == pbasic::TokenType::KW_END);
        REQUIRE(tokens[11].type == pbasic::TokenType::KW_LIST);
        REQUIRE(tokens[12].type == pbasic::TokenType::KW_RUN);
        REQUIRE(tokens[13].type == pbasic::TokenType::KW_NEW);
        REQUIRE(tokens[14].type == pbasic::TokenType::KW_EXIT);
        REQUIRE(tokens[15].type == pbasic::TokenType::FN_FREE);
        REQUIRE(tokens[16].type == pbasic::TokenType::FN_RND);
        REQUIRE(tokens[17].type == pbasic::TokenType::FN_ABS);
        REQUIRE(tokens[18].type == pbasic::TokenType::EOL);
    }
}
