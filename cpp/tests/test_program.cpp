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

    SECTION("set_line stores and replaces lines") {
        pbasic::Tokenizer tokenizer;
        prog.set_line(20, tokenizer.tokenize("PRINT 20"));
        prog.set_line(10, tokenizer.tokenize("PRINT 10"));
        REQUIRE(prog.line_count() == 2);
        REQUIRE(prog.has_line(10));
        REQUIRE(prog.has_line(20));

        // Replace line 10
        prog.set_line(10, tokenizer.tokenize("PRINT 100"));
        REQUIRE(prog.line_count() == 2);
    }

    SECTION("Line deletion via remove_line and empty tokens") {
        pbasic::Tokenizer tokenizer;
        prog.set_line(10, tokenizer.tokenize("PRINT 10"));
        prog.set_line(20, tokenizer.tokenize("PRINT 20"));
        REQUIRE(prog.line_count() == 2);

        // Delete via remove_line
        REQUIRE(prog.remove_line(10));
        REQUIRE_FALSE(prog.has_line(10));
        REQUIRE(prog.line_count() == 1);

        // Delete via empty line
        prog.set_line(20, tokenizer.tokenize(""));
        REQUIRE_FALSE(prog.has_line(20));
        REQUIRE(prog.empty());
    }
}
