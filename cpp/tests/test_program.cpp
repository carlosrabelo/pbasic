#include <catch.hpp>
#include <core/program.hpp>

TEST_CASE("Program line and container structures", "[program]") {
    pbasic::Program prog;

    SECTION("New program is empty") {
        REQUIRE(prog.empty());
        REQUIRE(prog.line_count() == 0);
    }

    SECTION("clear empties program") {
        prog.clear();
        REQUIRE(prog.empty());
    }
}
