#include <core/signals.hpp>
#include <csignal>
#include <signal.h>

namespace pbasic {

static volatile sig_atomic_t g_interrupted = 0;

extern "C" void sigint_handler(int) {
    g_interrupted = 1;
}

void install_signal_handlers() {
    struct sigaction sa{};
    sa.sa_handler = sigint_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0; // No SA_RESTART so blocking syscalls (read) fail with EINTR
    sigaction(SIGINT, &sa, nullptr);
}

bool check_interrupted() {
    return g_interrupted != 0;
}

bool check_and_reset_interrupted() {
    if (g_interrupted != 0) {
        g_interrupted = 0;
        return true;
    }
    return false;
}

void set_interrupted(bool interrupted) {
    g_interrupted = interrupted ? 1 : 0;
}

} // namespace pbasic
