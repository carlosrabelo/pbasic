#include <catch.hpp>
#include <core/evaluator.hpp>
#include <core/program.hpp>
#include <core/tokenizer.hpp>
#include <core/variables.hpp>

TEST_CASE("Factor evaluation in expressions", "[evaluator]") {
    pbasic::VariableStore vars;
    pbasic::Program prog;
    pbasic::Tokenizer tokenizer;
    uint16_t seed = 12345;

    vars.set('A', 42);
    vars.set('Z', 100);

    SECTION("Number literals") {
        auto t1 = tokenizer.tokenize("123");
        pbasic::Evaluator e1(t1, vars, prog, seed);
        REQUIRE(e1.eval_expression() == 123);
    }

    SECTION("Variables") {
        auto t1 = tokenizer.tokenize("A");
        pbasic::Evaluator e1(t1, vars, prog, seed);
        REQUIRE(e1.eval_expression() == 42);

        auto t2 = tokenizer.tokenize("Z");
        pbasic::Evaluator e2(t2, vars, prog, seed);
        REQUIRE(e2.eval_expression() == 100);
    }

    SECTION("Parentheses and unary minus") {
        auto t1 = tokenizer.tokenize("-15");
        pbasic::Evaluator e1(t1, vars, prog, seed);
        REQUIRE(e1.eval_expression() == -15);

        auto t2 = tokenizer.tokenize("-(A)");
        pbasic::Evaluator e2(t2, vars, prog, seed);
        REQUIRE(e2.eval_expression() == -42);

        auto t3 = tokenizer.tokenize("+50");
        pbasic::Evaluator e3(t3, vars, prog, seed);
        REQUIRE(e3.eval_expression() == 50);
    }

    SECTION("Built-in functions ABS, FREE, RND") {
        auto t1 = tokenizer.tokenize("ABS(-5)");
        pbasic::Evaluator e1(t1, vars, prog, seed);
        REQUIRE(e1.eval_expression() == 5);

        auto t2 = tokenizer.tokenize("FREE");
        pbasic::Evaluator e2(t2, vars, prog, seed);
        REQUIRE(e2.eval_expression() == 16384);

        auto t3 = tokenizer.tokenize("RND(10)");
        pbasic::Evaluator e3(t3, vars, prog, seed);
        int32_t r = e3.eval_expression();
        REQUIRE(r >= 1);
        REQUIRE(r <= 10);
    }

    SECTION("Multiplicative term parsing and 16-bit semantics") {
        auto t1 = tokenizer.tokenize("3 * 4");
        pbasic::Evaluator e1(t1, vars, prog, seed);
        REQUIRE(e1.eval_expression() == 12);

        auto t2 = tokenizer.tokenize("20 / 4");
        pbasic::Evaluator e2(t2, vars, prog, seed);
        REQUIRE(e2.eval_expression() == 5);

        auto t3 = tokenizer.tokenize("100 / 0");
        pbasic::Evaluator e3(t3, vars, prog, seed);
        REQUIRE(e3.eval_expression() == 65535);
    }

    SECTION("Additive expressions and operator precedence") {
        auto t1 = tokenizer.tokenize("2 + 3 * 4");
        pbasic::Evaluator e1(t1, vars, prog, seed);
        REQUIRE(e1.eval_expression() == 14);

        auto t2 = tokenizer.tokenize("(2 + 3) * 4");
        pbasic::Evaluator e2(t2, vars, prog, seed);
        REQUIRE(e2.eval_expression() == 20);

        auto t3 = tokenizer.tokenize("A + B");
        vars.set('A', 10);
        vars.set('B', 3);
        pbasic::Evaluator e3(t3, vars, prog, seed);
        REQUIRE(e3.eval_expression() == 13);

        auto t4 = tokenizer.tokenize("50 - 20 - 10");
        pbasic::Evaluator e4(t4, vars, prog, seed);
        REQUIRE(e4.eval_expression() == 20);
    }
}
