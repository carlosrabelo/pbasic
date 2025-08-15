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
}
