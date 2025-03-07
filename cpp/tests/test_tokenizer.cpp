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
}
