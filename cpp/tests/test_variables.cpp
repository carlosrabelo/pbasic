#include <catch.hpp>
#include <core/math.hpp>
#include <core/variables.hpp>

TEST_CASE("Variable store operations", "[variables]") {
    pbasic::VariableStore store;

    SECTION("All 26 variables initialized to 0") {
        for (char c = 'A'; c <= 'Z'; ++c) {
            REQUIRE(store.get(c) == 0);
        }
    }

    SECTION("Variable get and set across 32-bit range") {
        store.set('A', 42);
        store.set('B', -100000);
        store.set('Z', 1000000);

        REQUIRE(store.get('A') == 42);
        REQUIRE(store.get('B') == -100000);
        REQUIRE(store.get('Z') == 1000000);

        // Case insensitivity
        REQUIRE(store.get('a') == 42);
        store.set('a', 99);
        REQUIRE(store.get('A') == 99);
    }

    SECTION("clear() resets all variables to 0") {
        store.set('X', 500);
        store.set('Y', 600);
        store.clear();
        REQUIRE(store.get('X') == 0);
        REQUIRE(store.get('Y') == 0);
    }
}

TEST_CASE("16-bit and 32-bit mathematical engine", "[math]") {
    SECTION("16-bit multiplication with truncation") {
        REQUIRE(pbasic::mul16(100, 20) == 2000);
        // Truncation: 1000 * 100 = 100000 -> 100000 & 0xFFFF = 34464
        REQUIRE(pbasic::mul16(1000, 100) == 34464);
    }

    SECTION("16-bit division with zero protection") {
        REQUIRE(pbasic::div16(100, 5) == 20);
        REQUIRE(pbasic::div16(100, 0) == 0xFFFF);
    }

    SECTION("16-bit modulo with zero protection") {
        REQUIRE(pbasic::mod16(100, 30) == 10);
        REQUIRE(pbasic::mod16(100, 0) == 100);
    }

    SECTION("32-bit arithmetic helpers") {
        REQUIRE(pbasic::add32(100000, 200000) == 300000);
        REQUIRE(pbasic::sub32(100, 300) == -200);
        REQUIRE(pbasic::neg32(50) == -50);
        REQUIRE(pbasic::neg32(-50) == 50);
    }
}
