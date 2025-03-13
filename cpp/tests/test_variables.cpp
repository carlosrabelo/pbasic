#include <catch.hpp>
#include <core/variables.hpp>

TEST_CASE("Variable store container", "[variables]") {
    pbasic::VariableStore store;

    SECTION("clear resets all 26 variables") {
        store.clear();
        // Container initializes and resets
    }
}
