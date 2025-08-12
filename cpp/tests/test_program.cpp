#include <catch.hpp>
#include <core/program.hpp>
#include <core/tokenizer.hpp>
#include <sstream>

TEST_CASE("Program line and container structures", "[program]") {
    pbasic::Program prog;
    REQUIRE(prog.empty());
    REQUIRE(prog.line_count() == 0);
    REQUIRE(prog.get_first_line() == nullptr);
}

TEST_CASE("Program line insertion and replacement", "[program]") {
    pbasic::Program prog;
    pbasic::Tokenizer tokenizer;

    // Inserting lines out of order (30, 10, 20)
    prog.set_line(30, tokenizer.tokenize("END"));
    prog.set_line(10, tokenizer.tokenize("PRINT 1"));
    prog.set_line(20, tokenizer.tokenize("PRINT 2"));

    REQUIRE(prog.line_count() == 3);
    REQUIRE(prog.has_line(10));
    REQUIRE(prog.has_line(20));
    REQUIRE(prog.has_line(30));

    // Traversal is in sorted order
    const auto* first = prog.get_first_line();
    REQUIRE(first != nullptr);
    REQUIRE(first->line_number == 10);

    const auto* second = prog.get_next_line(10);
    REQUIRE(second != nullptr);
    REQUIRE(second->line_number == 20);

    const auto* third = prog.get_next_line(20);
    REQUIRE(third != nullptr);
    REQUIRE(third->line_number == 30);

    const auto* end = prog.get_next_line(30);
    REQUIRE(end == nullptr);

    // Replacement of existing line
    prog.set_line(20, tokenizer.tokenize("PRINT 99"));
    REQUIRE(prog.line_count() == 3);
    const auto* replaced = prog.get_line(20);
    REQUIRE(replaced != nullptr);
    REQUIRE(pbasic::detokenize(replaced->tokens) == "PRINT 99");
}

TEST_CASE("Program line deletion", "[program]") {
    pbasic::Program prog;
    pbasic::Tokenizer tokenizer;

    prog.set_line(10, tokenizer.tokenize("PRINT 1"));
    prog.set_line(20, tokenizer.tokenize("PRINT 2"));
    REQUIRE(prog.line_count() == 2);

    SECTION("Explicit remove_line") {
        REQUIRE(prog.remove_line(10));
        REQUIRE(!prog.has_line(10));
        REQUIRE(prog.line_count() == 1);
        REQUIRE(!prog.remove_line(999));
    }

    SECTION("Empty token sequence deletes line") {
        prog.set_line(10, tokenizer.tokenize(""));
        REQUIRE(!prog.has_line(10));
        REQUIRE(prog.line_count() == 1);
    }
}

TEST_CASE("Program listing and byte footprint", "[program]") {
    pbasic::Program prog;
    pbasic::Tokenizer tokenizer;

    prog.set_line(20, tokenizer.tokenize("GOTO 10"));
    prog.set_line(10, tokenizer.tokenize("PRINT \"LOOP\""));

    std::ostringstream out;
    prog.list(out);

    std::string expected =
        "10 PRINT \"LOOP\"\n"
        "20 GOTO 10\n";
    REQUIRE(out.str() == expected);

    REQUIRE(prog.byte_size() > 0);
}
