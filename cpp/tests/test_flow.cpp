#include <catch.hpp>
#include <core/interpreter.hpp>
#include <core/tokenizer.hpp>
#include <sstream>

TEST_CASE("Stored program runner", "[flow]") {
    std::ostringstream out;
    std::istringstream in;
    pbasic::IO io(out, in);
    pbasic::Program prog;
    pbasic::VariableStore vars;
    pbasic::Interpreter interp(io, prog, vars);
    pbasic::Tokenizer tokenizer;

    SECTION("RUN on empty program emits ?NO PROGRAM") {
        out.str("");
        interp.execute_line("RUN");
        REQUIRE(out.str() == "?NO PROGRAM\n");
    }

    SECTION("RUN executes lines sequentially") {
        prog.set_line(10, tokenizer.tokenize("PRINT \"LINE 10\""));
        prog.set_line(20, tokenizer.tokenize("PRINT \"LINE 20\""));
        out.str("");
        interp.execute_line("RUN");
        REQUIRE(out.str() == "LINE 10\nLINE 20\n");
    }

    SECTION("GOTO branches to target line") {
        prog.clear();
        prog.set_line(10, tokenizer.tokenize("GOTO 30"));
        prog.set_line(20, tokenizer.tokenize("PRINT \"SKIPPED\""));
        prog.set_line(30, tokenizer.tokenize("PRINT \"LANDED\""));
        out.str("");
        interp.execute_line("RUN");
        REQUIRE(out.str() == "LANDED\n");
    }

    SECTION("GOTO invalid line raises syntax error") {
        prog.clear();
        prog.set_line(10, tokenizer.tokenize("GOTO 999"));
        out.str("");
        interp.execute_line("RUN");
        REQUIRE(out.str() == "?SYNTAX ERROR\n");
    }

    SECTION("GOSUB and RETURN call stack") {
        prog.clear();
        prog.set_line(10, tokenizer.tokenize("GOSUB 100"));
        prog.set_line(20, tokenizer.tokenize("PRINT \"AFTER GOSUB\""));
        prog.set_line(30, tokenizer.tokenize("GOTO 200"));
        prog.set_line(100, tokenizer.tokenize("PRINT \"IN SUB\""));
        prog.set_line(110, tokenizer.tokenize("RETURN"));
        prog.set_line(200, tokenizer.tokenize("PRINT \"DONE\""));

        out.str("");
        interp.execute_line("RUN");
        REQUIRE(out.str() == "IN SUB\nAFTER GOSUB\nDONE\n");
    }

    SECTION("GOSUB stack overflow (>16 calls)") {
        prog.clear();
        for (int i = 1; i <= 17; ++i) {
            prog.set_line(i * 10, tokenizer.tokenize("GOSUB " + std::to_string((i + 1) * 10)));
        }
        out.str("");
        interp.execute_line("RUN");
        REQUIRE(out.str() == "?SYNTAX ERROR\n");
    }

    SECTION("RETURN without GOSUB raises syntax error") {
        prog.clear();
        prog.set_line(10, tokenizer.tokenize("RETURN"));
        out.str("");
        interp.execute_line("RUN");
        REQUIRE(out.str() == "?SYNTAX ERROR\n");
    }
}
