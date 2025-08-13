#include <catch.hpp>
#include <core/math.hpp>
#include <core/variables.hpp>

TEST_CASE("Variable store container", "[variables]") {
    pbasic::VariableStore store;

    SECTION("clear resets all 26 variables") {
        store.set('A', 100);
        store.clear();
        REQUIRE(store.get('A') == 0);
    }

    SECTION("get and set operations across A..Z") {
        for (char ch = 'A'; ch <= 'Z'; ++ch) {
            REQUIRE(store.get(ch) == 0);
        }

        store.set('A', 42);
        store.set('Z', -999);
        REQUIRE(store.get('A') == 42);
        REQUIRE(store.get('Z') == -999);
        REQUIRE(store.get('a') == 42); // case-insensitive check
    }
}

TEST_CASE("16-bit multiplication", "[math]") {
    SECTION("mul16 truncates to 16 bits") {
        REQUIRE(pbasic::mul16(10, 20) == 200);
        REQUIRE(pbasic::mul16(1000, 100) == static_cast<uint16_t>(100000 & 0xFFFF));
        REQUIRE(pbasic::mul16(0xFFFF, 2) == static_cast<uint16_t>((0xFFFF * 2) & 0xFFFF));
    }
}
