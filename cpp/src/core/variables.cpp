#include <core/variables.hpp>

namespace pbasic {

VariableStore::VariableStore() {
    clear();
}

void VariableStore::clear() {
    vars_.fill(0);
}

} // namespace pbasic
