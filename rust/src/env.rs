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

/// 16-bit unsigned multiplication with wrapping truncation.
pub fn mul16(a: u16, b: u16) -> u16 {
    a.wrapping_mul(b)
}

/// Safe 16-bit unsigned division returning 0xFFFF on division by zero.
pub fn div16(a: u16, b: u16) -> u16 {
    a.checked_div(b).unwrap_or(0xFFFF)
}

/// Safe 16-bit unsigned modulo returning unchanged dividend on division by zero.
pub fn mod16(a: u16, b: u16) -> u16 {
    a.checked_rem(b).unwrap_or(a)
}

/// Signed 32-bit addition.
pub fn add32(a: i32, b: i32) -> i32 {
    a.wrapping_add(b)
}

/// Signed 32-bit subtraction.
pub fn sub32(a: i32, b: i32) -> i32 {
    a.wrapping_sub(b)
}

/// Signed 32-bit negation.
pub fn neg32(a: i32) -> i32 {
    a.wrapping_neg()
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

    #[test]
    fn test_mul16_and_arithmetic() {
        assert_eq!(mul16(100, 20), 2000);
        assert_eq!(mul16(1000, 1000), (1_000_000u32 & 0xFFFF) as u16);

        assert_eq!(add32(100, 200), 300);
        assert_eq!(sub32(100, 200), -100);
        assert_eq!(neg32(15), -15);
        assert_eq!(neg32(-15), 15);
    }

    #[test]
    fn test_div16_and_mod16() {
        assert_eq!(div16(100, 5), 20);
        assert_eq!(div16(100, 0), 0xFFFF);

        assert_eq!(mod16(100, 30), 10);
        assert_eq!(mod16(100, 0), 100);
    }
}
