//! Expression and condition evaluator.

use crate::env::VariableStore;
use crate::program::Program;
use crate::token::{Token, TokenType};

pub struct Evaluator<'a> {
    pub(crate) tokens: &'a [Token],
    pub(crate) cursor: usize,
    pub(crate) vars: &'a mut VariableStore,
    pub(crate) prog: &'a Program,
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

    pub(crate) fn consume_token(&mut self, expected: TokenType) -> Result<(), String> {
        match self.peek() {
            Some(t) if t.token_type == expected => {
                self.advance();
                Ok(())
            }
            _ => Err("?SYNTAX ERROR".to_string()),
        }
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
            TokenType::Free => {
                self.advance();
                let used = self.prog.byte_size();
                let free_mem = 16384_usize.saturating_sub(used);
                Ok(free_mem as i32)
            }
            TokenType::Rnd => {
                self.advance();
                self.consume_token(TokenType::LParen)?;
                let arg = self.eval_expression()?;
                self.consume_token(TokenType::RParen)?;

                let raw = crate::env::next_rnd(self.rand_seed);
                if arg <= 0 {
                    Ok(raw as i32)
                } else {
                    let max = arg as u16;
                    let res = (raw % max) + 1;
                    Ok(res as i32)
                }
            }
            TokenType::Abs => {
                self.advance();
                self.consume_token(TokenType::LParen)?;
                let arg = self.eval_expression()?;
                self.consume_token(TokenType::RParen)?;
                Ok(if arg < 0 { arg.wrapping_neg() } else { arg })
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

    pub fn eval_term(&mut self) -> Result<i32, String> {
        let mut left = self.eval_factor()?;

        while let Some(tok) = self.peek() {
            match tok.token_type {
                TokenType::Asterisk => {
                    self.advance();
                    let right = self.eval_factor()?;
                    left = crate::env::mul16(left as u16, right as u16) as i32;
                }
                TokenType::Slash => {
                    self.advance();
                    let right = self.eval_factor()?;
                    left = crate::env::div16(left as u16, right as u16) as i32;
                }
                _ => break,
            }
        }

        Ok(left)
    }

    pub fn eval_expression(&mut self) -> Result<i32, String> {
        let mut left = self.eval_term()?;

        while let Some(tok) = self.peek() {
            match tok.token_type {
                TokenType::Plus => {
                    self.advance();
                    let right = self.eval_term()?;
                    left = left.wrapping_add(right);
                }
                TokenType::Minus => {
                    self.advance();
                    let right = self.eval_term()?;
                    left = left.wrapping_sub(right);
                }
                _ => break,
            }
        }

        Ok(left)
    }

    pub fn eval_condition(&mut self) -> Result<bool, String> {
        let left = self.eval_expression()?;

        let op_tok = match self.peek() {
            Some(t) => t.clone(),
            None => return Ok(left != 0),
        };

        match op_tok.token_type {
            TokenType::Equal => {
                self.advance();
                let right = self.eval_expression()?;
                Ok(left == right)
            }
            TokenType::NotEqual => {
                self.advance();
                let right = self.eval_expression()?;
                Ok(left != right)
            }
            TokenType::Less => {
                self.advance();
                let right = self.eval_expression()?;
                Ok(left < right)
            }
            TokenType::Greater => {
                self.advance();
                let right = self.eval_expression()?;
                Ok(left > right)
            }
            TokenType::LessEqual => {
                self.advance();
                let right = self.eval_expression()?;
                Ok(left <= right)
            }
            TokenType::GreaterEqual => {
                self.advance();
                let right = self.eval_expression()?;
                Ok(left >= right)
            }
            _ => Ok(left != 0),
        }
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

    #[test]
    fn test_eval_functions() {
        let mut vars = VariableStore::new();
        let prog = Program::new();
        let mut seed = 12345;

        // FREE
        let tokens1 = tokenize("FREE");
        let mut eval1 = Evaluator::new(&tokens1, &mut vars, &prog, &mut seed);
        assert_eq!(eval1.eval_factor().unwrap(), 16384);

        // ABS
        let tokens2 = tokenize("ABS(-5)");
        let mut eval2 = Evaluator::new(&tokens2, &mut vars, &prog, &mut seed);
        assert_eq!(eval2.eval_factor().unwrap(), 5);

        let tokens3 = tokenize("ABS(42)");
        let mut eval3 = Evaluator::new(&tokens3, &mut vars, &prog, &mut seed);
        assert_eq!(eval3.eval_factor().unwrap(), 42);

        // RND
        let tokens4 = tokenize("RND(10)");
        let mut eval4 = Evaluator::new(&tokens4, &mut vars, &prog, &mut seed);
        let rnd_val = eval4.eval_factor().unwrap();
        assert!((1..=10).contains(&rnd_val));
    }

    #[test]
    fn test_eval_term() {
        let mut vars = VariableStore::new();
        let prog = Program::new();
        let mut seed = 12345;

        let tokens1 = tokenize("10 * 20");
        let mut eval1 = Evaluator::new(&tokens1, &mut vars, &prog, &mut seed);
        assert_eq!(eval1.eval_term().unwrap(), 200);

        let tokens2 = tokenize("100 / 5");
        let mut eval2 = Evaluator::new(&tokens2, &mut vars, &prog, &mut seed);
        assert_eq!(eval2.eval_term().unwrap(), 20);

        // Division by zero returns 65535
        let tokens3 = tokenize("100 / 0");
        let mut eval3 = Evaluator::new(&tokens3, &mut vars, &prog, &mut seed);
        assert_eq!(eval3.eval_term().unwrap(), 65535);

        // Chained multiplication
        let tokens4 = tokenize("2 * 3 * 4");
        let mut eval4 = Evaluator::new(&tokens4, &mut vars, &prog, &mut seed);
        assert_eq!(eval4.eval_term().unwrap(), 24);
    }

    #[test]
    fn test_eval_expression() {
        let mut vars = VariableStore::new();
        let prog = Program::new();
        let mut seed = 12345;

        let tokens1 = tokenize("10 + 20");
        let mut eval1 = Evaluator::new(&tokens1, &mut vars, &prog, &mut seed);
        assert_eq!(eval1.eval_expression().unwrap(), 30);

        let tokens2 = tokenize("100 - 35");
        let mut eval2 = Evaluator::new(&tokens2, &mut vars, &prog, &mut seed);
        assert_eq!(eval2.eval_expression().unwrap(), 65);

        // Operator precedence: 2 + 3 * 4 = 14
        let tokens3 = tokenize("2 + 3 * 4");
        let mut eval3 = Evaluator::new(&tokens3, &mut vars, &prog, &mut seed);
        assert_eq!(eval3.eval_expression().unwrap(), 14);

        // Parentheses override precedence: (2 + 3) * 4 = 20
        let tokens4 = tokenize("(2 + 3) * 4");
        let mut eval4 = Evaluator::new(&tokens4, &mut vars, &prog, &mut seed);
        assert_eq!(eval4.eval_expression().unwrap(), 20);

        // Negative result
        let tokens5 = tokenize("10 - 50");
        let mut eval5 = Evaluator::new(&tokens5, &mut vars, &prog, &mut seed);
        assert_eq!(eval5.eval_expression().unwrap(), -40);
    }

    #[test]
    fn test_eval_condition() {
        let mut vars = VariableStore::new();
        let prog = Program::new();
        let mut seed = 12345;

        let pairs = [
            ("10 = 10", true),
            ("10 = 20", false),
            ("10 <> 20", true),
            ("10 <> 10", false),
            ("5 < 10", true),
            ("10 < 5", false),
            ("10 > 5", true),
            ("5 > 10", false),
            ("5 <= 5", true),
            ("5 <= 4", false),
            ("5 >= 5", true),
            ("4 >= 5", false),
            ("1", true),
            ("0", false),
        ];

        for (expr, expected) in pairs {
            let tokens = tokenize(expr);
            let mut eval = Evaluator::new(&tokens, &mut vars, &prog, &mut seed);
            assert_eq!(
                eval.eval_condition().unwrap(),
                expected,
                "Failed for: {}",
                expr
            );
        }
    }
}
