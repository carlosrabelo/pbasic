//! PBasic interpreter library.

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
