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
}
