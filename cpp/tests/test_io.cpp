#include <catch.hpp>
#include <core/io.hpp>
#include <core/repl.hpp>
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

    SECTION("classify_line correctly classifies numbered, immediate, and empty lines") {
        auto p1 = pbasic::classify_line("10 PRINT \"HI\"");
        REQUIRE(p1.type == pbasic::LineType::Numbered);
        REQUIRE(p1.line_number == 10);
        REQUIRE(p1.content == "PRINT \"HI\"");

        auto p2 = pbasic::classify_line("65535 END");
        REQUIRE(p2.type == pbasic::LineType::Numbered);
        REQUIRE(p2.line_number == 65535);
        REQUIRE(p2.content == "END");

        auto p3 = pbasic::classify_line("PRINT 123");
        REQUIRE(p3.type == pbasic::LineType::Immediate);
        REQUIRE(p3.content == "PRINT 123");

        auto p4 = pbasic::classify_line("   ");
        REQUIRE(p4.type == pbasic::LineType::Empty);
    }

    SECTION("REPL runs loop and exits cleanly on EXIT") {
        std::ostringstream out;
        std::istringstream in("10 PRINT 1\nPRINT 2\nEXIT\n");
        pbasic::IO io(out, in);
        pbasic::REPL repl(io);

        std::vector<std::pair<uint16_t, std::string>> numbered;
        std::vector<std::string> immediate;

        repl.set_numbered_handler([&](uint16_t num, const std::string& line) {
            numbered.emplace_back(num, line);
        });
        repl.set_immediate_handler([&](const std::string& line) {
            immediate.push_back(line);
            return true;
        });

        repl.run();

        REQUIRE(out.str() == "> > > ");
        REQUIRE(numbered.size() == 1);
        REQUIRE(numbered[0].first == 10);
        REQUIRE(numbered[0].second == "PRINT 1");
        REQUIRE(immediate.size() == 1);
        REQUIRE(immediate[0] == "PRINT 2");
    }
}
