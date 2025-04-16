//! Core statement execution engine and interpreter.

use crate::env::VariableStore;
use crate::program::Program;
use crate::token::{Token, TokenType};
use std::io::{self, Write};

pub struct Interpreter {
    pub vars: VariableStore,
    pub prog: Program,
    pub rand_seed: u16,
    pub call_stack: Vec<u16>,
    pub running: bool,
    pub exit_requested: bool,
}

impl Default for Interpreter {
    fn default() -> Self {
        Self::new()
    }
}

impl Interpreter {
    pub fn new() -> Self {
        Self {
            vars: VariableStore::new(),
            prog: Program::new(),
            rand_seed: 12345,
            call_stack: Vec::new(),
            running: false,
            exit_requested: false,
        }
    }

    pub fn execute_statement<W: Write>(
        &mut self,
        tokens: &[Token],
        writer: &mut W,
    ) -> io::Result<()> {
        if tokens.is_empty() {
            return Ok(());
        }

        match &tokens[0].token_type {
            TokenType::Print => self.exec_print(&tokens[1..], writer),
            TokenType::Let => self.exec_let(&tokens[1..], writer),
            TokenType::New => self.exec_new(writer),
            TokenType::Rem => Ok(()),
            TokenType::Free => self.exec_free(writer),
            TokenType::Variable(_)
                if tokens.len() > 1 && tokens[1].token_type == TokenType::Equal =>
            {
                self.exec_let(tokens, writer)
            }
            TokenType::Eol => Ok(()),
            _ => writeln!(writer, "?SYNTAX ERROR"),
        }
    }

    pub fn exec_print<W: Write>(&mut self, _tokens: &[Token], _writer: &mut W) -> io::Result<()> {
        Ok(())
    }

    pub fn exec_let<W: Write>(&mut self, _tokens: &[Token], _writer: &mut W) -> io::Result<()> {
        Ok(())
    }

    pub fn exec_new<W: Write>(&mut self, _writer: &mut W) -> io::Result<()> {
        Ok(())
    }

    pub fn exec_free<W: Write>(&mut self, _writer: &mut W) -> io::Result<()> {
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::tokenize;

    #[test]
    fn test_dispatcher_syntax_error() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();
        let tokens = tokenize("UNKNOWN_COMMAND");
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "?SYNTAX ERROR\n");
    }

    #[test]
    fn test_dispatcher_empty_or_eol() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();
        interp.execute_statement(&[], &mut buf).unwrap();
        assert!(buf.is_empty());

        let tokens = tokenize("");
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert!(buf.is_empty());
    }
}
