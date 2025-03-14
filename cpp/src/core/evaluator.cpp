#include <core/evaluator.hpp>
#include <cmath>

namespace pbasic {

const Token Evaluator::s_eof_token{TokenType::END_OF_INPUT, "", 0, '\0'};

Evaluator::Evaluator(const std::vector<Token>& tokens, VariableStore& vars, Program& prog, uint16_t& rand_seed)
    : tokens_(tokens), vars_(vars), prog_(prog), rand_seed_(rand_seed) {}

bool Evaluator::is_at_end() const {
    return cursor_ >= tokens_.size() || tokens_[cursor_].type == TokenType::EOL || tokens_[cursor_].type == TokenType::END_OF_INPUT;
}

const Token& Evaluator::current() const {
    if (cursor_ < tokens_.size()) {
        return tokens_[cursor_];
    }
    return s_eof_token;
}

const Token& Evaluator::advance() {
    if (cursor_ < tokens_.size()) {
        return tokens_[cursor_++];
    }
    return s_eof_token;
}

bool Evaluator::check(TokenType type) const {
    return current().type == type;
}

bool Evaluator::match(TokenType type) {
    if (check(type)) {
        advance();
        return true;
    }
    return false;
}

int32_t Evaluator::eval_factor() {
    if (match(TokenType::NUMBER)) {
        return tokens_[cursor_ - 1].number_value;
    }

    if (match(TokenType::VARIABLE)) {
        return vars_.get(tokens_[cursor_ - 1].var_name);
    }

    if (match(TokenType::LPAREN)) {
        int32_t val = eval_expression();
        match(TokenType::RPAREN);
        return val;
    }

    if (match(TokenType::MINUS)) {
        return -eval_factor();
    }

    if (match(TokenType::PLUS)) {
        return eval_factor();
    }

    advance();
    return 0;
}

int32_t Evaluator::eval_term() {
    return eval_factor();
}

int32_t Evaluator::eval_expression() {
    return eval_term();
}

bool Evaluator::eval_condition() {
    return eval_expression() != 0;
}

} // namespace pbasic
