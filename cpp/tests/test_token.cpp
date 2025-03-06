#include <catch.hpp>
#include <core/token.hpp>

TEST_CASE("Token types and structures behave correctly", "[token]") {
    SECTION("Token default initialization") {
        pbasic::Token tok;
        REQUIRE(tok.type == pbasic::TokenType::ILLEGAL);
        REQUIRE(tok.text.empty());
        REQUIRE(tok.number_value == 0);
        REQUIRE(tok.var_name == '\0');
    }

    SECTION("Token type names match keywords and operators") {
        REQUIRE(std::string(pbasic::token_type_name(pbasic::TokenType::KW_PRINT)) == "PRINT");
        REQUIRE(std::string(pbasic::token_type_name(pbasic::TokenType::PLUS)) == "+");
        REQUIRE(std::string(pbasic::token_type_name(pbasic::TokenType::NOT_EQUAL)) == "<>");
    }

    SECTION("Token equality comparison") {
        pbasic::Token t1{pbasic::TokenType::NUMBER, "123", 123, '\0'};
        pbasic::Token t2{pbasic::TokenType::NUMBER, "123", 123, '\0'};
        pbasic::Token t3{pbasic::TokenType::NUMBER, "456", 456, '\0'};
        REQUIRE(t1 == t2);
        REQUIRE(!(t1 == t3));
    }
}
