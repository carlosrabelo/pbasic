//! Token representations for PBasic lexical analysis.

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TokenType {
    // Keywords
    Let,
    Goto,
    Gosub,
    Print,
    If,
    Input,
    Return,
    End,
    List,
    Run,
    New,
    Exit,
    Rem,
    Then,

    // Built-in functions
    Free,
    Rnd,
    Abs,

    // Literals & Identifiers
    Number(i32),
    String(String),
    Variable(char), // 'A'..'Z'

    // Operators
    Plus,
    Minus,
    Asterisk,
    Slash,
    Equal,
    NotEqual,
    Less,
    Greater,
    LessEqual,
    GreaterEqual,

    // Punctuation & Control
    LParen,
    RParen,
    Comma,
    Semicolon,
    Colon,
    Eol,
    Eof,
    Illegal,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Token {
    pub token_type: TokenType,
    pub text: String,
}

impl Token {
    pub fn new(token_type: TokenType, text: impl Into<String>) -> Self {
        Self {
            token_type,
            text: text.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_token_creation() {
        let t1 = Token::new(TokenType::Let, "LET");
        assert_eq!(t1.token_type, TokenType::Let);
        assert_eq!(t1.text, "LET");

        let t2 = Token::new(TokenType::Number(42), "42");
        assert_eq!(t2.token_type, TokenType::Number(42));

        let t3 = Token::new(TokenType::Variable('X'), "X");
        assert_eq!(t3.token_type, TokenType::Variable('X'));
    }
}
