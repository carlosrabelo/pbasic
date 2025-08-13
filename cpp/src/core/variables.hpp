#pragma once

#include <array>
#include <cstdint>
#include <cstddef>

namespace pbasic {

class VariableStore {
public:
    VariableStore();

    void clear();
    int32_t get(char name) const;
    void set(char name, int32_t value);

private:
    std::array<int32_t, 26> vars_;
    static size_t var_index(char name);
};

} // namespace pbasic
