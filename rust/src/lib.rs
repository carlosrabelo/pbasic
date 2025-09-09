//! PBasic interpreter library.

pub mod repl;
pub mod signals;
pub mod token;

pub fn banner() -> &'static str {
    "PBasic\n"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_banner() {
        assert_eq!(banner(), "PBasic\n");
    }
}
