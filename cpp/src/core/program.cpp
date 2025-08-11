#include <core/program.hpp>

namespace pbasic {

void Program::clear() {
    lines_.clear();
}

bool Program::empty() const {
    return lines_.empty();
}

size_t Program::line_count() const {
    return lines_.size();
}

} // namespace pbasic
