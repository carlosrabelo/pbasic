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

    SECTION("Program line traversal via get_first_line and get_next_line") {
        pbasic::Tokenizer tokenizer;
        prog.set_line(30, tokenizer.tokenize("PRINT 30"));
        prog.set_line(10, tokenizer.tokenize("PRINT 10"));
        prog.set_line(20, tokenizer.tokenize("PRINT 20"));

        const auto* line1 = prog.get_first_line();
        REQUIRE(line1 != nullptr);
        REQUIRE(line1->line_number == 10);

        const auto* line2 = prog.get_next_line(10);
        REQUIRE(line2 != nullptr);
        REQUIRE(line2->line_number == 20);

        const auto* line3 = prog.get_next_line(20);
        REQUIRE(line3 != nullptr);
        REQUIRE(line3->line_number == 30);

        const auto* line4 = prog.get_next_line(30);
        REQUIRE(line4 == nullptr);
    }
}
