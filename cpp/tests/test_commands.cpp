#include <catch.hpp>
#include <core/interpreter.hpp>
#include <sstream>

TEST_CASE("Command dispatcher skeleton", "[commands]") {
    std::ostringstream out;
    std::istringstream in;
    pbasic::IO io(out, in);
    pbasic::Program prog;
    pbasic::VariableStore vars;
    pbasic::Interpreter interp(io, prog, vars);

    SECTION("Syntax error on unrecognized token") {
        out.str("");
        interp.execute_line("@FOO");
        REQUIRE(out.str() == "?SYNTAX ERROR\n");
    }

    SECTION("Empty line returns Ok") {
        out.str("");
        interp.execute_line("");
        REQUIRE(out.str().empty());
    }

    SECTION("PRINT string literals") {
        out.str("");
        interp.execute_line("PRINT \"HELLO, WORLD!\"");
        REQUIRE(out.str() == "HELLO, WORLD!\n");
    }

    SECTION("PRINT semicolon suppresses newline") {
        out.str("");
        interp.execute_line("PRINT \"HI \";");
        interp.execute_line("PRINT \"THERE\"");
        REQUIRE(out.str() == "HI THERE\n");
    }

    SECTION("PRINT comma inserts 8 spaces") {
        out.str("");
        interp.execute_line("PRINT 1, 2");
        REQUIRE(out.str() == "1        2\n");
    }

    SECTION("PRINT expressions") {
        out.str("");
        interp.execute_line("PRINT 10 + 20");
        REQUIRE(out.str() == "30\n");
    }

    SECTION("LET assignment and variable update") {
        interp.execute_line("LET A = 42");
        REQUIRE(vars.get('A') == 42);

        out.str("");
        interp.execute_line("PRINT A");
        REQUIRE(out.str() == "42\n");

        interp.execute_line("B = 100");
        REQUIRE(vars.get('B') == 100);
    }

    SECTION("Syntax error on invalid LET") {
        out.str("");
        interp.execute_line("LET = 123");
        REQUIRE(out.str() == "?SYNTAX ERROR\n");
    }
}
