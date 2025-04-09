//! Signal handling routines for graceful program interruption.

use std::sync::atomic::{AtomicBool, Ordering};

pub static INTERRUPTED: AtomicBool = AtomicBool::new(false);

extern "C" fn sigint_handler(_sig: i32) {
    INTERRUPTED.store(true, Ordering::SeqCst);
}

unsafe extern "C" {
    fn signal(signum: i32, handler: extern "C" fn(i32)) -> usize;
}

/// Installs signal handler for SIGINT (Ctrl+C).
pub fn install_signal_handlers() {
    unsafe {
        signal(2, sigint_handler);
    }
}

/// Checks if SIGINT has been caught, resetting the flag to false.
pub fn check_and_reset_interrupted() -> bool {
    INTERRUPTED.swap(false, Ordering::SeqCst)
}

/// Manually sets the interrupted flag (useful for testing).
pub fn set_interrupted(val: bool) {
    INTERRUPTED.store(val, Ordering::SeqCst);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_interrupted_flag() {
        set_interrupted(false);
        assert!(!check_and_reset_interrupted());

        set_interrupted(true);
        assert!(check_and_reset_interrupted());
        assert!(!check_and_reset_interrupted());
    }
}
