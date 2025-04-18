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
    pub current_line_no: u16,
    pub branch_target: u16,
    pub branch_taken: bool,
    pub halted: bool,
    pub is_running: bool,
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
            current_line_no: 0,
            branch_target: 0,
            branch_taken: false,
            halted: false,
            is_running: false,
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
            TokenType::Run => self.run_program(writer),
            TokenType::List => self.prog.list(writer),
            TokenType::Goto => self.exec_goto(&tokens[1..], writer),
            TokenType::Gosub => self.exec_gosub(&tokens[1..], writer),
            TokenType::Return => self.exec_return(writer),
            TokenType::If => self.exec_if(&tokens[1..], writer),
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

    pub fn exec_new<W: Write>(&mut self, writer: &mut W) -> io::Result<()> {
        self.prog.clear();
        self.vars.clear();
        self.call_stack.clear();
        writeln!(writer, "OK")
    }

    pub fn exec_free<W: Write>(&mut self, writer: &mut W) -> io::Result<()> {
        let free_mem = 16384_usize.saturating_sub(self.prog.byte_size());
        writeln!(writer, "{}", free_mem)
    }

    pub fn exec_goto<W: Write>(&mut self, tokens: &[Token], writer: &mut W) -> io::Result<()> {
        let mut eval = crate::evaluator::Evaluator::new(
            tokens,
            &mut self.vars,
            &self.prog,
            &mut self.rand_seed,
        );
        let target_val = match eval.eval_expression() {
            Ok(v) if v > 0 && v <= 65535 => v as u16,
            _ => {
                self.halted = true;
                writeln!(writer, "?SYNTAX ERROR")?;
                return Ok(());
            }
        };

        if !self.prog.has_line(target_val) {
            self.halted = true;
            writeln!(writer, "?SYNTAX ERROR")?;
            return Ok(());
        }

        self.branch_target = target_val;
        self.branch_taken = true;
        Ok(())
    }

    pub fn exec_gosub<W: Write>(&mut self, tokens: &[Token], writer: &mut W) -> io::Result<()> {
        if self.call_stack.len() >= 16 {
            self.halted = true;
            writeln!(writer, "?SYNTAX ERROR")?;
            return Ok(());
        }

        let mut eval = crate::evaluator::Evaluator::new(
            tokens,
            &mut self.vars,
            &self.prog,
            &mut self.rand_seed,
        );
        let target_val = match eval.eval_expression() {
            Ok(v) if v > 0 && v <= 65535 => v as u16,
            _ => {
                self.halted = true;
                writeln!(writer, "?SYNTAX ERROR")?;
                return Ok(());
            }
        };

        if !self.prog.has_line(target_val) {
            self.halted = true;
            writeln!(writer, "?SYNTAX ERROR")?;
            return Ok(());
        }

        let return_line_no = self
            .prog
            .next_line(self.current_line_no)
            .map(|l| l.line_number)
            .unwrap_or(0);

        self.call_stack.push(return_line_no);
        self.branch_target = target_val;
        self.branch_taken = true;
        Ok(())
    }

    pub fn exec_return<W: Write>(&mut self, writer: &mut W) -> io::Result<()> {
        let return_line_no = match self.call_stack.pop() {
            Some(line) => line,
            None => {
                self.halted = true;
                writeln!(writer, "?SYNTAX ERROR")?;
                return Ok(());
            }
        };

        if return_line_no == 0 {
            self.halted = true;
        } else {
            self.branch_target = return_line_no;
            self.branch_taken = true;
        }
        Ok(())
    }

    pub fn exec_if<W: Write>(&mut self, tokens: &[Token], writer: &mut W) -> io::Result<()> {
        let mut eval = crate::evaluator::Evaluator::new(
            tokens,
            &mut self.vars,
            &self.prog,
            &mut self.rand_seed,
        );

        let cond = match eval.eval_condition() {
            Ok(c) => c,
            Err(_) => {
                self.halted = true;
                writeln!(writer, "?SYNTAX ERROR")?;
                return Ok(());
            }
        };

        if eval.peek().map(|t| &t.token_type) != Some(&TokenType::Then) {
            self.halted = true;
            writeln!(writer, "?SYNTAX ERROR")?;
            return Ok(());
        }
        eval.advance(); // consume THEN

        if !cond {
            return Ok(());
        }

        let remaining = &tokens[eval.cursor..];
        if remaining.is_empty() {
            return Ok(());
        }

        if let TokenType::Number(_) = remaining[0].token_type {
            self.exec_goto(remaining, writer)
        } else {
            self.execute_statement(remaining, writer)
        }
    }

    pub fn run_program<W: Write>(&mut self, writer: &mut W) -> io::Result<()> {
        if self.prog.is_empty() {
            writeln!(writer, "?NO PROGRAM")?;
            return Ok(());
        }

        self.call_stack.clear();
        self.halted = false;
        self.is_running = true;

        let mut cur = self.prog.first_line().cloned();

        while let Some(line) = cur {
            if self.halted || self.exit_requested {
                break;
            }

            if crate::signals::check_and_reset_interrupted() {
                self.halted = true;
                writeln!(writer)?;
                break;
            }

            self.current_line_no = line.line_number;
            self.branch_taken = false;

            self.execute_statement(&line.tokens, writer)?;

            if self.halted || self.exit_requested {
                break;
            }

            if self.branch_taken {
                cur = self.prog.get_line(self.branch_target).cloned();
            } else {
                cur = self.prog.next_line(self.current_line_no).cloned();
            }
        }

        self.is_running = false;
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

    #[test]
    fn test_exec_new() {
        let mut interp = Interpreter::new();
        interp.vars.set('A', 42);
        interp.prog.set_line(10, vec![], "PRINT 10".to_string());
        interp.call_stack.push(10);

        let mut buf = Vec::new();
        let tokens = tokenize("NEW");
        interp.execute_statement(&tokens, &mut buf).unwrap();

        assert_eq!(String::from_utf8(buf).unwrap(), "OK\n");
        assert_eq!(interp.vars.get('A'), 0);
        assert!(interp.prog.is_empty());
        assert!(interp.call_stack.is_empty());
    }

    #[test]
    fn test_exec_rem_and_free() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();

        // REM
        let tokens1 = tokenize("REM this is a comment");
        interp.execute_statement(&tokens1, &mut buf).unwrap();
        assert!(buf.is_empty());

        // FREE
        let tokens2 = tokenize("FREE");
        interp.execute_statement(&tokens2, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "16384\n");
    }

    #[test]
    fn test_run_program() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();

        // Empty program
        let tokens = tokenize("RUN");
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "?NO PROGRAM\n");

        // Stored program
        buf.clear();
        interp.prog.set_line(
            10,
            tokenize("PRINT \"LINE 10\""),
            "PRINT \"LINE 10\"".to_string(),
        );
        interp.prog.set_line(
            20,
            tokenize("PRINT \"LINE 20\""),
            "PRINT \"LINE 20\"".to_string(),
        );
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert_eq!(
            String::from_utf8(buf.clone()).unwrap(),
            "LINE 10\nLINE 20\n"
        );
    }

    #[test]
    fn test_exec_goto() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();

        // Jump forward skipping line 20
        interp
            .prog
            .set_line(10, tokenize("GOTO 30"), "GOTO 30".to_string());
        interp.prog.set_line(
            20,
            tokenize("PRINT \"SKIPPED\""),
            "PRINT \"SKIPPED\"".to_string(),
        );
        interp.prog.set_line(
            30,
            tokenize("PRINT \"TARGET\""),
            "PRINT \"TARGET\"".to_string(),
        );

        let tokens = tokenize("RUN");
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "TARGET\n");

        // Non-existent target
        buf.clear();
        interp.prog.clear();
        interp
            .prog
            .set_line(10, tokenize("GOTO 99"), "GOTO 99".to_string());
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "?SYNTAX ERROR\n");
    }

    #[test]
    fn test_exec_gosub_and_return() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();

        interp
            .prog
            .set_line(10, tokenize("GOSUB 100"), "GOSUB 100".to_string());
        interp
            .prog
            .set_line(20, tokenize("PRINT \"BACK\""), "PRINT \"BACK\"".to_string());
        interp
            .prog
            .set_line(30, tokenize("GOTO 999"), "GOTO 999".to_string());
        interp
            .prog
            .set_line(100, tokenize("PRINT \"SUB\""), "PRINT \"SUB\"".to_string());
        interp
            .prog
            .set_line(110, tokenize("RETURN"), "RETURN".to_string());
        interp
            .prog
            .set_line(999, tokenize("REM end"), "REM end".to_string());

        let tokens = tokenize("RUN");
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "SUB\nBACK\n");

        // Stack underflow
        buf.clear();
        interp.prog.clear();
        interp
            .prog
            .set_line(10, tokenize("RETURN"), "RETURN".to_string());
        interp.execute_statement(&tokens, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "?SYNTAX ERROR\n");
    }

    #[test]
    fn test_exec_if() {
        let mut interp = Interpreter::new();
        let mut buf = Vec::new();

        // True branch executes PRINT
        let tokens1 = tokenize("IF 10 > 5 THEN PRINT \"YES\"");
        interp.execute_statement(&tokens1, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf.clone()).unwrap(), "YES\n");

        // False branch does not execute PRINT
        buf.clear();
        let tokens2 = tokenize("IF 10 < 5 THEN PRINT \"NO\"");
        interp.execute_statement(&tokens2, &mut buf).unwrap();
        assert!(buf.is_empty());

        // IF condition with numeric GOTO branch
        buf.clear();
        interp.prog.set_line(
            10,
            tokenize("IF 1 = 1 THEN 30"),
            "IF 1 = 1 THEN 30".to_string(),
        );
        interp
            .prog
            .set_line(20, tokenize("PRINT \"NO\""), "PRINT \"NO\"".to_string());
        interp
            .prog
            .set_line(30, tokenize("PRINT \"YES\""), "PRINT \"YES\"".to_string());

        let run_tokens = tokenize("RUN");
        interp.execute_statement(&run_tokens, &mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "YES\n");
    }
}
