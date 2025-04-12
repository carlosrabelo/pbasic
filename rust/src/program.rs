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

    pub fn remove_line(&mut self, line_no: u16) -> bool {
        self.lines.remove(&line_no).is_some()
    }

    pub fn get_line(&self, line_no: u16) -> Option<&ProgramLine> {
        self.lines.get(&line_no)
    }

    pub fn first_line(&self) -> Option<&ProgramLine> {
        self.lines.values().next()
    }

    pub fn next_line(&self, current: u16) -> Option<&ProgramLine> {
        use std::ops::Bound;
        self.lines
            .range((Bound::Excluded(current), Bound::Unbounded))
            .next()
            .map(|(_, line)| line)
    }

    pub fn list<W: std::io::Write>(&self, writer: &mut W) -> std::io::Result<()> {
        for (line_no, line) in &self.lines {
            let text = if !line.tokens.is_empty() {
                crate::lexer::format_tokens(&line.tokens)
            } else {
                line.raw_text.clone()
            };
            writeln!(writer, "{} {}", line_no, text)?;
        }
        Ok(())
    }

    pub fn byte_size(&self) -> usize {
        let mut total = 0;
        for line in self.lines.values() {
            let text = if !line.tokens.is_empty() {
                crate::lexer::format_tokens(&line.tokens)
            } else {
                line.raw_text.clone()
            };
            total += 4 + text.len() + 1;
        }
        total
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

    #[test]
    fn test_remove_line() {
        let mut prog = Program::new();
        prog.set_line(10, vec![], "PRINT 10".to_string());
        prog.set_line(20, vec![], "PRINT 20".to_string());

        assert!(prog.remove_line(10));
        assert!(!prog.has_line(10));
        assert_eq!(prog.len(), 1);

        assert!(!prog.remove_line(99));
        assert_eq!(prog.len(), 1);
    }

    #[test]
    fn test_first_and_next_line() {
        let mut prog = Program::new();
        assert!(prog.first_line().is_none());
        assert!(prog.next_line(10).is_none());

        prog.set_line(10, vec![], "PRINT 10".to_string());
        prog.set_line(30, vec![], "PRINT 30".to_string());
        prog.set_line(20, vec![], "PRINT 20".to_string());

        let first = prog.first_line().unwrap();
        assert_eq!(first.line_number, 10);

        let second = prog.next_line(10).unwrap();
        assert_eq!(second.line_number, 20);

        let third = prog.next_line(20).unwrap();
        assert_eq!(third.line_number, 30);

        assert!(prog.next_line(30).is_none());
    }

    #[test]
    fn test_list_and_byte_size() {
        let mut prog = Program::new();
        prog.set_line(20, vec![], "PRINT 20".to_string());
        prog.set_line(10, vec![], "PRINT 10".to_string());

        let mut buf = Vec::new();
        prog.list(&mut buf).unwrap();
        let listing = String::from_utf8(buf).unwrap();
        assert_eq!(listing, "10 PRINT 10\n20 PRINT 20\n");

        assert_eq!(prog.byte_size(), (4 + 8 + 1) * 2);
    }
}
