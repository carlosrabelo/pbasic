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

    pub fn exec_print<W: Write>(&mut self, tokens: &[Token], writer: &mut W) -> io::Result<()> {
        let mut cursor = 0;
        let mut trailing_semicolon = false;

        while cursor < tokens.len() {
            let tok = &tokens[cursor];
            match &tok.token_type {
                TokenType::Eol => break,
                TokenType::Semicolon => {
                    trailing_semicolon = true;
                    cursor += 1;
                }
                TokenType::Comma => {
                    write!(writer, "        ")?;
                    trailing_semicolon = false;
                    cursor += 1;
                }
                TokenType::String(s) => {
                    write!(writer, "{}", s)?;
                    trailing_semicolon = false;
                    cursor += 1;
                }
                _ => {
                    let mut eval = crate::evaluator::Evaluator::new(
                        &tokens[cursor..],
                        &mut self.vars,
                        &self.prog,
                        &mut self.rand_seed,
                    );
                    match eval.eval_expression() {
                        Ok(val) => {
                            write!(writer, "{}", val)?;
                            cursor += eval.cursor;
                            trailing_semicolon = false;
                        }
                        Err(_) => {
                            writeln!(writer, "?SYNTAX ERROR")?;
                            return Ok(());
                        }
                    }
                }
            }
        }

        if !trailing_semicolon {
            writeln!(writer)?;
        }
        Ok(())
    }

    pub fn exec_let<W: Write>(&mut self, tokens: &[Token], writer: &mut W) -> io::Result<()> {
        if tokens.is_empty() {
            writeln!(writer, "?SYNTAX ERROR")?;
            return Ok(());
        }

        let var_name = match tokens[0].token_type {
            TokenType::Variable(c) => c,
            _ => {
                writeln!(writer, "?SYNTAX ERROR")?;
                return Ok(());
            }
        };

        if tokens.len() < 2 || tokens[1].token_type != TokenType::Equal {
            writeln!(writer, "?SYNTAX ERROR")?;
            return Ok(());
        }

        let expr_tokens = &tokens[2..];
        let mut eval = crate::evaluator::Evaluator::new(
            expr_tokens,
            &mut self.vars,
            &self.prog,
            &mut self.rand_seed,
        );

        match eval.eval_expression() {
            Ok(val) => {
                self.vars.set(var_name, val);
            }
            Err(_) => {
                writeln!(writer, "?SYNTAX ERROR")?;
            }
        }

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

    #[test]
    fn test_exec_print() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();

        // String
        let tokens1 = tokenize("PRINT \"HELLO, WORLD!\"");
        interp.execute_statement(&tokens1, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "HELLO, WORLD!\n");

        // Expression
        buf.clear();
        let tokens2 = tokenize("PRINT 10 + 20");
        interp.execute_statement(&tokens2, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "30\n");

        // Semicolon suppression
        buf.clear();
        let tokens3 = tokenize("PRINT \"HI \";");
        interp.execute_statement(&tokens3, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "HI ");

        // Comma tab
        buf.clear();
        let tokens4 = tokenize("PRINT 1, 2");
        interp.execute_statement(&tokens4, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "1        2\n");
    }

    #[test]
    fn test_exec_let() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();

        let tokens1 = tokenize("LET A = 42");
        interp.execute_statement(&tokens1, &mut buf).unwrap();
        assert_eq!(interp.vars.get('A'), 42);

        let tokens2 = tokenize("LET B = A * 2");
        interp.execute_statement(&tokens2, &mut buf).unwrap();
        assert_eq!(interp.vars.get('B'), 84);

        // Implicit LET
        let tokens3 = tokenize("C = 100");
        interp.execute_statement(&tokens3, &mut buf).unwrap();
        assert_eq!(interp.vars.get('C'), 100);

        // Syntax error
        let tokens4 = tokenize("LET 123");
        interp.execute_statement(&tokens4, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "?SYNTAX ERROR\n");
    }
}
