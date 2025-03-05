#include <catch.hpp>
#include <core/io.hpp>
#include <sstream>

TEST_CASE("Console I/O output helpers", "[io]") {
    std::ostringstream out;
    std::istringstream in;
    pbasic::IO io(out, in);

    SECTION("print_str outputs exact text without newline") {
        io.print_str("Hello World");
        REQUIRE(out.str() == "Hello World");
    }

    SECTION("print_number outputs formatted integer") {
        io.print_number(12345);
        REQUIRE(out.str() == "12345");
        out.str("");
        io.print_number(-42);
        REQUIRE(out.str() == "-42");
    }

    SECTION("print_crlf outputs standard newline") {
        io.print_crlf();
        REQUIRE(out.str() == "\n");
    }

    SECTION("print_ok outputs OK followed by newline") {
        io.print_ok();
        REQUIRE(out.str() == "OK\n");
    }

    SECTION("fold_case uppercases characters outside quotes and preserves inside quotes") {
        REQUIRE(pbasic::fold_case("print \"hello world\"") == "PRINT \"hello world\"");
        REQUIRE(pbasic::fold_case("let a = 10") == "LET A = 10");
        REQUIRE(pbasic::fold_case("\"keep lower\" and UPPER") == "\"keep lower\" AND UPPER");
    }

    SECTION("read_line normalizes CRLF and applies fold_case") {
        std::istringstream stream("print \"hello\"\r\nlet b = 2\n");
        pbasic::IO custom_io(out, stream);

        auto l1 = custom_io.read_line();
        REQUIRE(l1.has_value());
        REQUIRE(*l1 == "PRINT \"hello\"");

        auto l2 = custom_io.read_line();
        REQUIRE(l2.has_value());
        REQUIRE(*l2 == "LET B = 2");

        auto l3 = custom_io.read_line();
        REQUIRE_FALSE(l3.has_value());
    }
}
