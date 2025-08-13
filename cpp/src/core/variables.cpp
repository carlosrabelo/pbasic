#include <core/variables.hpp>

namespace pbasic {

VariableStore::VariableStore() {
    clear();
}

void VariableStore::clear() {
    vars_.fill(0);
}

size_t VariableStore::var_index(char name) {
    if (name >= 'a' && name <= 'z') {
        name = static_cast<char>(name - 'a' + 'A');
    }
    if (name >= 'A' && name <= 'Z') {
        return static_cast<size_t>(name - 'A');
    }
    return 0;
}

int32_t VariableStore::get(char name) const {
    return vars_[var_index(name)];
}

void VariableStore::set(char name, int32_t value) {
    vars_[var_index(name)] = value;
}

} // namespace pbasic
