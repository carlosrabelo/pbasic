//! Variables and environment store.

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VariableStore {
    pub(crate) vars: [i32; 26],
}

impl Default for VariableStore {
    fn default() -> Self {
        Self::new()
    }
}

impl VariableStore {
    pub fn new() -> Self {
        Self { vars: [0; 26] }
    }

    pub fn clear(&mut self) {
        self.vars.fill(0);
    }

    pub fn count(&self) -> usize {
        26
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_variable_store_initialization_and_clear() {
        let mut store = VariableStore::new();
        assert_eq!(store.count(), 26);
        for &v in store.vars.iter() {
            assert_eq!(v, 0);
        }

        store.vars[0] = 42;
        store.vars[25] = -99;
        assert_eq!(store.vars[0], 42);
        assert_eq!(store.vars[25], -99);

        store.clear();
        for &v in store.vars.iter() {
            assert_eq!(v, 0);
        }
    }
}
