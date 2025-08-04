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
}
