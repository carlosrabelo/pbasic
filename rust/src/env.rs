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

    pub fn get(&self, name: char) -> i32 {
        let idx = var_index(name);
        self.vars[idx]
    }

    pub fn set(&mut self, name: char, val: i32) {
        let idx = var_index(name);
        self.vars[idx] = val;
    }
}

pub fn var_index(name: char) -> usize {
    let upper = name.to_ascii_uppercase();
    if upper.is_ascii_uppercase() {
        (upper as usize) - ('A' as usize)
    } else {
        0
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

    #[test]
    fn test_variable_get_set() {
        let mut store = VariableStore::new();
        assert_eq!(store.get('A'), 0);
        assert_eq!(store.get('z'), 0);

        store.set('A', 12345);
        store.set('z', -98765);
        store.set('M', i32::MAX);

        assert_eq!(store.get('a'), 12345);
        assert_eq!(store.get('Z'), -98765);
        assert_eq!(store.get('m'), i32::MAX);

        store.clear();
        assert_eq!(store.get('A'), 0);
        assert_eq!(store.get('Z'), 0);
    }
}
