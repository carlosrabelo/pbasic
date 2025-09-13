//! Expression and condition evaluator.

use crate::env::VariableStore;
use crate::program::Program;
use crate::token::{Token, TokenType};

pub struct Evaluator<'a> {
    pub(crate) tokens: &'a [Token],
    pub(crate) cursor: usize,
    pub(crate) vars: &'a mut VariableStore,
    #[allow(dead_code)]
    pub(crate) prog: &'a Program,
    #[allow(dead_code)]
    pub(crate) rand_seed: &'a mut u16,
}

impl<'a> Evaluator<'a> {
    pub fn new(
        tokens: &'a [Token],
        vars: &'a mut VariableStore,
        prog: &'a Program,
        rand_seed: &'a mut u16,
    ) -> Self {
        Self {
            tokens,
            cursor: 0,
            vars,
            prog,
            rand_seed,
        }
    }

    pub(crate) fn peek(&self) -> Option<&Token> {
        self.tokens.get(self.cursor)
    }

    pub(crate) fn advance(&mut self) -> Option<&Token> {
        let tok = self.tokens.get(self.cursor);
        if tok.is_some() {
            self.cursor += 1;
        }
        tok
    }

    pub fn eval_factor(&mut self) -> Result<i32, String> {
        let tok = match self.peek() {
            Some(t) => t.clone(),
            None => return Err("?SYNTAX ERROR".to_string()),
        };

        match tok.token_type {
            TokenType::Number(val) => {
                self.advance();
                Ok(val)
            }
            TokenType::Variable(name) => {
                self.advance();
                Ok(self.vars.get(name))
            }
            TokenType::Minus => {
                self.advance();
                let val = self.eval_factor()?;
                Ok(val.wrapping_neg())
            }
            TokenType::LParen => {
                self.advance();
                let val = self.eval_expression()?;
                match self.peek() {
                    Some(t) if t.token_type == TokenType::RParen => {
                        self.advance();
                        Ok(val)
                    }
                    _ => Err("?SYNTAX ERROR".to_string()),
                }
            }
            _ => Err("?SYNTAX ERROR".to_string()),
        }
    }

    pub fn eval_expression(&mut self) -> Result<i32, String> {
        self.eval_factor()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::tokenize;

    #[test]
    fn test_eval_factor() {
        let mut vars = VariableStore::new();
        vars.set('A', 42);
        let prog = Program::new();
        let mut seed = 12345;

        // Number
        let tokens1 = tokenize("100");
        let mut eval1 = Evaluator::new(&tokens1, &mut vars, &prog, &mut seed);
        assert_eq!(eval1.eval_factor().unwrap(), 100);

        // Variable
        let tokens2 = tokenize("A");
        let mut eval2 = Evaluator::new(&tokens2, &mut vars, &prog, &mut seed);
        assert_eq!(eval2.eval_factor().unwrap(), 42);

        // Unary minus
        let tokens3 = tokenize("-15");
        let mut eval3 = Evaluator::new(&tokens3, &mut vars, &prog, &mut seed);
        assert_eq!(eval3.eval_factor().unwrap(), -15);

        // Parentheses
        let tokens4 = tokenize("(50)");
        let mut eval4 = Evaluator::new(&tokens4, &mut vars, &prog, &mut seed);
        assert_eq!(eval4.eval_factor().unwrap(), 50);
    }
}
