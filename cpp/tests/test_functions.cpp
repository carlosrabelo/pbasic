#include <catch.hpp>
#include <core/interpreter.hpp>
#include <sstream>

TEST_CASE("Interactive user input via INPUT", "[functions]") {
    SECTION("INPUT with default prompt") {
        std::ostringstream out;
        std::istringstream in("42\n");
        pbasic::IO io(out, in);
        pbasic::Program prog;
        pbasic::VariableStore vars;
        pbasic::Interpreter interp(io, prog, vars);

        interp.execute_line("INPUT A");
        REQUIRE(out.str() == "? ");
        REQUIRE(vars.get('A') == 42);
    }

    SECTION("INPUT with custom prompt string") {
        std::ostringstream out;
        std::istringstream in("100\n");
        pbasic::IO io(out, in);
        pbasic::Program prog;
        pbasic::VariableStore vars;
        pbasic::Interpreter interp(io, prog, vars);

        interp.execute_line("INPUT \"GUESS: \"; B");
        REQUIRE(out.str() == "GUESS: ");
        REQUIRE(vars.get('B') == 100);
    }

    SECTION("INPUT syntax errors") {
        std::ostringstream out;
        std::istringstream in("\n");
        pbasic::IO io(out, in);
        pbasic::Program prog;
        pbasic::VariableStore vars;
        pbasic::Interpreter interp(io, prog, vars);

        interp.execute_line("INPUT 123");
        REQUIRE(out.str() == "? ?SYNTAX ERROR\n");
    }

    SECTION("PRNG generator and RND function") {
        std::ostringstream out;
        std::istringstream in;
        pbasic::IO io(out, in);
        pbasic::Program prog;
        pbasic::VariableStore vars;
        pbasic::Interpreter interp(io, prog, vars, 12345);

        // Seed 12345: (12345 * 25173 + 13849) & 0xFFFF = 2822
        out.str("");
        interp.execute_line("PRINT RND(0)");
        REQUIRE(out.str() == "2822\n");

        // RND with positive argument scales to 1..N
        for (int i = 0; i < 20; ++i) {
            out.str("");
            interp.execute_line("PRINT RND(6)");
            int val = std::stoi(out.str());
            REQUIRE(val >= 1);
            REQUIRE(val <= 6);
        }
    }
}
