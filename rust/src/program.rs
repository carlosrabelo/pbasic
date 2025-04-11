//! Program storage and line management.

use crate::token::Token;
use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProgramLine {
    pub line_number: u16,
    pub tokens: Vec<Token>,
    pub raw_text: String,
}

impl ProgramLine {
    pub fn new(line_number: u16, tokens: Vec<Token>, raw_text: impl Into<String>) -> Self {
        Self {
            line_number,
            tokens,
            raw_text: raw_text.into(),
        }
    }
}

#[derive(Debug, Default, Clone)]
pub struct Program {
    pub(crate) lines: BTreeMap<u16, ProgramLine>,
}

impl Program {
    pub fn new() -> Self {
        Self {
            lines: BTreeMap::new(),
        }
    }

    pub fn clear(&mut self) {
        self.lines.clear();
    }

    pub fn is_empty(&self) -> bool {
        self.lines.is_empty()
    }

    pub fn len(&self) -> usize {
        self.lines.len()
    }

    pub fn has_line(&self, line_no: u16) -> bool {
        self.lines.contains_key(&line_no)
    }

    pub fn set_line(&mut self, line_no: u16, tokens: Vec<Token>, raw_text: String) {
        let line = ProgramLine::new(line_no, tokens, raw_text);
        self.lines.insert(line_no, line);
    }

    pub fn get_line(&self, line_no: u16) -> Option<&ProgramLine> {
        self.lines.get(&line_no)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_program_container_creation() {
        let mut prog = Program::new();
        assert!(prog.is_empty());
        assert_eq!(prog.len(), 0);
        assert!(!prog.has_line(10));
        assert!(prog.get_line(10).is_none());

        let line = ProgramLine::new(10, vec![], "PRINT 10");
        assert_eq!(line.line_number, 10);
        assert_eq!(line.raw_text, "PRINT 10");

        prog.clear();
        assert!(prog.is_empty());
    }

    #[test]
    fn test_set_line_and_replacement() {
        let mut prog = Program::new();
        prog.set_line(30, vec![], "PRINT 30".to_string());
        prog.set_line(10, vec![], "PRINT 10".to_string());
        prog.set_line(20, vec![], "PRINT 20".to_string());

        assert_eq!(prog.len(), 3);
        let keys: Vec<u16> = prog.lines.keys().copied().collect();
        assert_eq!(keys, vec![10, 20, 30]);

        // Replacement
        prog.set_line(20, vec![], "PRINT 200".to_string());
        assert_eq!(prog.len(), 3);
        assert_eq!(prog.get_line(20).unwrap().raw_text, "PRINT 200");
    }
}
