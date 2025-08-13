#pragma once

#include <array>
#include <cstdint>
#include <cstddef>

namespace pbasic {

class VariableStore {
public:
    VariableStore();

    void clear();

protected:
    std::array<int32_t, 26> vars_;
};

} // namespace pbasic
