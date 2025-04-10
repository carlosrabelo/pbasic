//! Lexical scanner for PBasic tokenization.

use crate::token::{Token, TokenType};

pub struct Lexer {
    chars: Vec<char>,
    pos: usize,
}

impl Lexer {
    pub fn new(input: &str) -> Self {
        Self {
            chars: input.chars().collect(),
            pos: 0,
        }
    }

    fn peek(&self) -> Option<char> {
        self.chars.get(self.pos).copied()
    }

    fn advance(&mut self) -> Option<char> {
        let ch = self.chars.get(self.pos).copied();
        if ch.is_some() {
            self.pos += 1;
        }
        ch
    }

    fn skip_whitespace(&mut self) {
        while let Some(ch) = self.peek() {
            if ch == ' ' || ch == '\t' {
                self.advance();
            } else {
                break;
            }
        }
    }

    pub fn scan_tokens(&mut self) -> Vec<Token> {
        let mut tokens = Vec::new();

        loop {
            self.skip_whitespace();
            let ch = match self.peek() {
                Some(c) => c,
                None => {
                    tokens.push(Token::new(TokenType::Eol, ""));
                    break;
                }
            };

            match ch {
                '(' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::LParen, "("));
                }
                ')' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::RParen, ")"));
                }
                ',' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Comma, ","));
                }
                ';' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Semicolon, ";"));
                }
                ':' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Colon, ":"));
                }
                '+' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Plus, "+"));
                }
                '-' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Minus, "-"));
                }
                '*' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Asterisk, "*"));
                }
                '/' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Slash, "/"));
                }
                _ => {
                    // Unhandled characters for now
                    self.advance();
                    tokens.push(Token::new(TokenType::Illegal, ch.to_string()));
                }
            }
        }

        tokens
    }
}

pub fn tokenize(input: &str) -> Vec<Token> {
    let mut lexer = Lexer::new(input);
    lexer.scan_tokens()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_punctuation_and_whitespace() {
        let tokens = tokenize("  (  ) , ; : + - * /  ");
        let types: Vec<TokenType> = tokens.into_iter().map(|t| t.token_type).collect();
        assert_eq!(
            types,
            vec![
                TokenType::LParen,
                TokenType::RParen,
                TokenType::Comma,
                TokenType::Semicolon,
                TokenType::Colon,
                TokenType::Plus,
                TokenType::Minus,
                TokenType::Asterisk,
                TokenType::Slash,
                TokenType::Eol,
            ]
        );
    }
}
