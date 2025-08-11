#include <catch.hpp>
#include <core/tokenizer.hpp>

TEST_CASE("Tokenizer scanner loop and basic punctuation", "[tokenizer]") {
    pbasic::Tokenizer tokenizer;

    SECTION("Skips whitespace and emits EOL on empty input") {
        auto tokens = tokenizer.tokenize("   \t  ");
        REQUIRE(tokens.size() == 1);
        REQUIRE(tokens[0].type == pbasic::TokenType::EOL);
    }

    SECTION("Scans single-character punctuation and arithmetic operators") {
        auto tokens = tokenizer.tokenize(" (  ) , ; + - * / ");
        REQUIRE(tokens.size() == 9);
        REQUIRE(tokens[0].type == pbasic::TokenType::LPAREN);
        REQUIRE(tokens[1].type == pbasic::TokenType::RPAREN);
        REQUIRE(tokens[2].type == pbasic::TokenType::COMMA);
        REQUIRE(tokens[3].type == pbasic::TokenType::SEMICOLON);
        REQUIRE(tokens[4].type == pbasic::TokenType::PLUS);
        REQUIRE(tokens[5].type == pbasic::TokenType::MINUS);
        REQUIRE(tokens[6].type == pbasic::TokenType::ASTERISK);
        REQUIRE(tokens[7].type == pbasic::TokenType::SLASH);
        REQUIRE(tokens[8].type == pbasic::TokenType::EOL);
    }
}

TEST_CASE("Tokenizer keywords, functions, and variables", "[tokenizer]") {
    pbasic::Tokenizer tokenizer;

    SECTION("Scans all 14 keywords") {
        auto tokens = tokenizer.tokenize("LET GOTO GOSUB PRINT IF INPUT RETURN END LIST RUN NEW EXIT REM THIS IS A COMMENT\n");
        REQUIRE(tokens[0].type == pbasic::TokenType::KW_LET);
        REQUIRE(tokens[1].type == pbasic::TokenType::KW_GOTO);
        REQUIRE(tokens[2].type == pbasic::TokenType::KW_GOSUB);
        REQUIRE(tokens[3].type == pbasic::TokenType::KW_PRINT);
        REQUIRE(tokens[4].type == pbasic::TokenType::KW_IF);
        REQUIRE(tokens[5].type == pbasic::TokenType::KW_INPUT);
        REQUIRE(tokens[6].type == pbasic::TokenType::KW_RETURN);
        REQUIRE(tokens[7].type == pbasic::TokenType::KW_END);
        REQUIRE(tokens[8].type == pbasic::TokenType::KW_LIST);
        REQUIRE(tokens[9].type == pbasic::TokenType::KW_RUN);
        REQUIRE(tokens[10].type == pbasic::TokenType::KW_NEW);
        REQUIRE(tokens[11].type == pbasic::TokenType::KW_EXIT);
        REQUIRE(tokens[12].type == pbasic::TokenType::KW_REM);
        REQUIRE(tokens[12].text == " THIS IS A COMMENT\n");
        REQUIRE(tokens[13].type == pbasic::TokenType::EOL);
    }

    SECTION("Scans THEN keyword and built-in functions") {
        auto tokens = tokenizer.tokenize("THEN FREE RND ABS");
        REQUIRE(tokens[0].type == pbasic::TokenType::KW_THEN);
        REQUIRE(tokens[1].type == pbasic::TokenType::FN_FREE);
        REQUIRE(tokens[2].type == pbasic::TokenType::FN_RND);
        REQUIRE(tokens[3].type == pbasic::TokenType::FN_ABS);
        REQUIRE(tokens[4].type == pbasic::TokenType::EOL);
    }

    SECTION("Scans single letter variables A-Z") {
        auto tokens = tokenizer.tokenize("A B Z");
        REQUIRE(tokens[0].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[0].var_name == 'A');
        REQUIRE(tokens[1].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[1].var_name == 'B');
        REQUIRE(tokens[2].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[2].var_name == 'Z');
        REQUIRE(tokens[3].type == pbasic::TokenType::EOL);
    }

    SECTION("Applies boundary rule (LETTER is not LET + TER)") {
        auto tokens = tokenizer.tokenize("LETTER");
        REQUIRE(tokens[0].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[0].var_name == 'L');
        REQUIRE(tokens[1].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[1].var_name == 'E');
        REQUIRE(tokens[2].type == pbasic::TokenType::VARIABLE);
        REQUIRE(tokens[2].var_name == 'T');
    }
}

TEST_CASE("Tokenizer literals and relational operators", "[tokenizer]") {
    pbasic::Tokenizer tokenizer;

    SECTION("Scans multi-digit numeric literals") {
        auto tokens = tokenizer.tokenize("0 123 65535");
        REQUIRE(tokens.size() == 4);
        REQUIRE(tokens[0].type == pbasic::TokenType::NUMBER);
        REQUIRE(tokens[0].number_value == 0);
        REQUIRE(tokens[1].type == pbasic::TokenType::NUMBER);
        REQUIRE(tokens[1].number_value == 123);
        REQUIRE(tokens[2].type == pbasic::TokenType::NUMBER);
        REQUIRE(tokens[2].number_value == 65535);
        REQUIRE(tokens[3].type == pbasic::TokenType::EOL);
    }

    SECTION("Scans string literals preserving spaces and punctuation") {
        auto tokens = tokenizer.tokenize("\"HELLO, WORLD! 123\"");
        REQUIRE(tokens.size() == 2);
        REQUIRE(tokens[0].type == pbasic::TokenType::STRING);
        REQUIRE(tokens[0].text == "HELLO, WORLD! 123");
        REQUIRE(tokens[1].type == pbasic::TokenType::EOL);
    }

    SECTION("Scans relational comparison operators") {
        auto tokens = tokenizer.tokenize("= <> < > <= >=");
        REQUIRE(tokens.size() == 7);
        REQUIRE(tokens[0].type == pbasic::TokenType::EQUAL);
        REQUIRE(tokens[1].type == pbasic::TokenType::NOT_EQUAL);
        REQUIRE(tokens[2].type == pbasic::TokenType::LESS);
        REQUIRE(tokens[3].type == pbasic::TokenType::GREATER);
        REQUIRE(tokens[4].type == pbasic::TokenType::LESS_EQUAL);
        REQUIRE(tokens[5].type == pbasic::TokenType::GREATER_EQUAL);
        REQUIRE(tokens[6].type == pbasic::TokenType::EOL);
    }
}

TEST_CASE("Token detokenizer formatting", "[tokenizer]") {
    pbasic::Tokenizer tokenizer;

    SECTION("Detokenizes statements into canonical BASIC format") {
        auto t1 = tokenizer.tokenize("LET A = 5");
        REQUIRE(pbasic::detokenize(t1) == "LET A = 5");

        auto t2 = tokenizer.tokenize("PRINT \"HELLO\"; X");
        REQUIRE(pbasic::detokenize(t2) == "PRINT \"HELLO\"; X");

        auto t3 = tokenizer.tokenize("IF X > 10 THEN 20");
        REQUIRE(pbasic::detokenize(t3) == "IF X > 10 THEN 20");

        auto t4 = tokenizer.tokenize("REM A TEST COMMENT");
        REQUIRE(pbasic::detokenize(t4) == "REM A TEST COMMENT");

        auto t5 = tokenizer.tokenize("GOTO 100");
        REQUIRE(pbasic::detokenize(t5) == "GOTO 100");
    }
}
