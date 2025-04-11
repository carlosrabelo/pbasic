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
                '=' => {
                    self.advance();
                    tokens.push(Token::new(TokenType::Equal, "="));
                }
                '<' => {
                    self.advance();
                    if self.peek() == Some('>') {
                        self.advance();
                        tokens.push(Token::new(TokenType::NotEqual, "<>"));
                    } else if self.peek() == Some('=') {
                        self.advance();
                        tokens.push(Token::new(TokenType::LessEqual, "<="));
                    } else {
                        tokens.push(Token::new(TokenType::Less, "<"));
                    }
                }
                '>' => {
                    self.advance();
                    if self.peek() == Some('=') {
                        self.advance();
                        tokens.push(Token::new(TokenType::GreaterEqual, ">="));
                    } else {
                        tokens.push(Token::new(TokenType::Greater, ">"));
                    }
                }
                '"' => {
                    self.advance();
                    let s = self.read_string();
                    tokens.push(Token::new(TokenType::String(s.clone()), s));
                }
                _ if ch.is_ascii_digit() => {
                    let (num_str, val) = self.read_number();
                    tokens.push(Token::new(TokenType::Number(val), num_str));
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

    fn read_string(&mut self) -> String {
        let mut s = String::new();
        while let Some(ch) = self.peek() {
            if ch == '"' {
                self.advance();
                break;
            }
            if ch == '\n' || ch == '\r' {
                break;
            }
            s.push(ch);
            self.advance();
        }
        s
    }

    fn read_number(&mut self) -> (String, i32) {
        let mut s = String::new();
        while let Some(ch) = self.peek() {
            if ch.is_ascii_digit() {
                s.push(ch);
                self.advance();
            } else {
                break;
            }
        }
        let val = s.parse::<i32>().unwrap_or(0);
        (s, val)
    }
}

pub fn tokenize(input: &str) -> Vec<Token> {
    let mut lexer = Lexer::new(input);
    lexer.scan_tokens()
}

/// Reconstructs a canonical BASIC text representation from tokens.
pub fn format_tokens(tokens: &[Token]) -> String {
    let mut s = String::new();

    for tok in tokens {
        match &tok.token_type {
            TokenType::Let => s.push_str("LET "),
            TokenType::Goto => s.push_str("GOTO "),
            TokenType::Gosub => s.push_str("GOSUB "),
            TokenType::Print => s.push_str("PRINT "),
            TokenType::If => s.push_str("IF "),
            TokenType::Input => s.push_str("INPUT "),
            TokenType::Return => s.push_str("RETURN"),
            TokenType::End => s.push_str("END"),
            TokenType::List => s.push_str("LIST"),
            TokenType::Run => s.push_str("RUN"),
            TokenType::New => s.push_str("NEW"),
            TokenType::Exit => s.push_str("EXIT"),
            TokenType::Rem => {
                s.push_str("REM ");
                s.push_str(&tok.text);
            }
            TokenType::Then => s.push_str(" THEN "),
            TokenType::Free => s.push_str("FREE"),
            TokenType::Rnd => s.push_str("RND"),
            TokenType::Abs => s.push_str("ABS"),
            TokenType::Number(val) => s.push_str(&val.to_string()),
            TokenType::String(lit) => {
                s.push('"');
                s.push_str(lit);
                s.push('"');
            }
            TokenType::Variable(v) => s.push(*v),
            TokenType::Plus => s.push_str(" + "),
            TokenType::Minus => {
                if s.is_empty() || s.ends_with('(') || s.ends_with(' ') {
                    s.push('-');
                } else {
                    s.push_str(" - ");
                }
            }
            TokenType::Asterisk => s.push_str(" * "),
            TokenType::Slash => s.push_str(" / "),
            TokenType::Equal => s.push_str(" = "),
            TokenType::NotEqual => s.push_str(" <> "),
            TokenType::Less => s.push_str(" < "),
            TokenType::Greater => s.push_str(" > "),
            TokenType::LessEqual => s.push_str(" <= "),
            TokenType::GreaterEqual => s.push_str(" >= "),
            TokenType::LParen => s.push('('),
            TokenType::RParen => s.push(')'),
            TokenType::Comma => s.push_str(", "),
            TokenType::Semicolon => s.push_str("; "),
            TokenType::Colon => s.push_str(" : "),
            TokenType::Eol | TokenType::Eof | TokenType::Illegal => {}
        }
    }

    s
}

/// Alias for format_tokens.
pub fn detokenize(tokens: &[Token]) -> String {
    format_tokens(tokens)
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

    #[test]
    fn test_literals_and_operators() {
        let tokens = tokenize("100 \"HELLO WORLD\" = <> < <= > >=");
        let types: Vec<TokenType> = tokens.into_iter().map(|t| t.token_type).collect();
        assert_eq!(
            types,
            vec![
                TokenType::Number(100),
                TokenType::String("HELLO WORLD".to_string()),
                TokenType::Equal,
                TokenType::NotEqual,
                TokenType::Less,
                TokenType::LessEqual,
                TokenType::Greater,
                TokenType::GreaterEqual,
                TokenType::Eol,
            ]
        );
    }

    #[test]
    fn test_detokenizer() {
        let original = "LET A = 10 + 20";
        let tokens = tokenize(original);
        let reconstructed = detokenize(&tokens);
        assert_eq!(reconstructed, "LET A = 10 + 20");

        let original2 = "PRINT \"HELLO\"; X";
        let tokens2 = tokenize(original2);
        let reconstructed2 = detokenize(&tokens2);
        assert_eq!(reconstructed2, "PRINT \"HELLO\"; X");
    }
}
