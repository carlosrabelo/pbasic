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

    if (match(TokenType::FN_FREE)) {
        return static_cast<int32_t>(16384 - prog_.byte_size());
    }

    if (match(TokenType::FN_RND)) {
        match(TokenType::LPAREN);
        int32_t x = eval_expression();
        match(TokenType::RPAREN);
        rand_seed_ = static_cast<uint16_t>((static_cast<uint32_t>(rand_seed_) * 25173 + 13849) & 0xFFFF);
        if (x <= 0) {
            return static_cast<int32_t>(rand_seed_);
        }
        return static_cast<int32_t>((rand_seed_ % static_cast<uint16_t>(x)) + 1);
    }

    if (match(TokenType::FN_ABS)) {
        match(TokenType::LPAREN);
        int32_t val = eval_expression();
        match(TokenType::RPAREN);
        return std::abs(val);
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
