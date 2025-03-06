#pragma once

namespace pbasic {

void install_signal_handlers();
bool check_interrupted();
bool check_and_reset_interrupted();
void set_interrupted(bool interrupted);

} // namespace pbasic
