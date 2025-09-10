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
                _ if ch.is_ascii_alphabetic() => {
                    let ident = self.read_identifier();
                    match ident.as_str() {
                        "LET" => tokens.push(Token::new(TokenType::Let, "LET")),
                        "GOTO" => tokens.push(Token::new(TokenType::Goto, "GOTO")),
                        "GOSUB" => tokens.push(Token::new(TokenType::Gosub, "GOSUB")),
                        "PRINT" => tokens.push(Token::new(TokenType::Print, "PRINT")),
                        "IF" => tokens.push(Token::new(TokenType::If, "IF")),
                        "INPUT" => tokens.push(Token::new(TokenType::Input, "INPUT")),
                        "RETURN" => tokens.push(Token::new(TokenType::Return, "RETURN")),
                        "END" => tokens.push(Token::new(TokenType::End, "END")),
                        "LIST" => tokens.push(Token::new(TokenType::List, "LIST")),
                        "RUN" => tokens.push(Token::new(TokenType::Run, "RUN")),
                        "NEW" => tokens.push(Token::new(TokenType::New, "NEW")),
                        "EXIT" => tokens.push(Token::new(TokenType::Exit, "EXIT")),
                        "THEN" => tokens.push(Token::new(TokenType::Then, "THEN")),
                        "FREE" => tokens.push(Token::new(TokenType::Free, "FREE")),
                        "RND" => tokens.push(Token::new(TokenType::Rnd, "RND")),
                        "ABS" => tokens.push(Token::new(TokenType::Abs, "ABS")),
                        "REM" => {
                            self.skip_whitespace();
                            let comment = self.read_rest_of_line();
                            tokens.push(Token::new(TokenType::Rem, comment));
                        }
                        var if var.len() == 1 => {
                            let v = var.chars().next().unwrap();
                            tokens.push(Token::new(TokenType::Variable(v), var));
                        }
                        _ => tokens.push(Token::new(TokenType::Illegal, ident)),
                    }
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

    fn read_identifier(&mut self) -> String {
        let mut ident = String::new();
        while let Some(ch) = self.peek() {
            if ch.is_ascii_alphabetic() {
                ident.push(ch);
                self.advance();
            } else {
                break;
            }
        }
        ident
    }

    fn read_rest_of_line(&mut self) -> String {
        let mut rest = String::new();
        while let Some(ch) = self.peek() {
            if ch == '\n' || ch == '\r' {
                break;
            }
            rest.push(ch);
            self.advance();
        }
        rest
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

    #[test]
    fn test_keywords_and_variables() {
        let tokens =
            tokenize("LET A PRINT IF THEN GOTO GOSUB RETURN END LIST RUN NEW EXIT FREE RND ABS");
        let types: Vec<TokenType> = tokens.into_iter().map(|t| t.token_type).collect();
        assert_eq!(
            types,
            vec![
                TokenType::Let,
                TokenType::Variable('A'),
                TokenType::Print,
                TokenType::If,
                TokenType::Then,
                TokenType::Goto,
                TokenType::Gosub,
                TokenType::Return,
                TokenType::End,
                TokenType::List,
                TokenType::Run,
                TokenType::New,
                TokenType::Exit,
                TokenType::Free,
                TokenType::Rnd,
                TokenType::Abs,
                TokenType::Eol,
            ]
        );
    }

    #[test]
    fn test_rem_comment() {
        let tokens = tokenize("REM This is a test comment 123");
        assert_eq!(tokens[0].token_type, TokenType::Rem);
        assert_eq!(tokens[0].text, "This is a test comment 123");
    }
}
