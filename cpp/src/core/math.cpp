#include <core/math.hpp>

namespace pbasic {

uint16_t mul16(uint16_t a, uint16_t b) {
    return static_cast<uint16_t>((static_cast<uint32_t>(a) * static_cast<uint32_t>(b)) & 0xFFFF);
}

uint16_t div16(uint16_t a, uint16_t b) {
    if (b == 0) {
        return 65535;
    }
    return static_cast<uint16_t>(a / b);
}

uint16_t mod16(uint16_t a, uint16_t b) {
    if (b == 0) {
        return a;
    }
    return static_cast<uint16_t>(a % b);
}

int32_t add32(int32_t a, int32_t b) {
    return a + b;
}

int32_t sub32(int32_t a, int32_t b) {
    return a - b;
}

int32_t neg32(int32_t a) {
    return -a;
}

} // namespace pbasic
