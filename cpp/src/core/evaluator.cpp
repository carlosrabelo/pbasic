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
    int32_t left = eval_factor();

    while (check(TokenType::ASTERISK) || check(TokenType::SLASH)) {
        TokenType op = advance().type;
        int32_t right = eval_factor();

        uint16_t uleft = static_cast<uint16_t>(left & 0xFFFF);
        uint16_t uright = static_cast<uint16_t>(right & 0xFFFF);

        if (op == TokenType::ASTERISK) {
            left = static_cast<int32_t>(mul16(uleft, uright));
        } else {
            left = static_cast<int32_t>(div16(uleft, uright));
        }
    }

    return left;
}

int32_t Evaluator::eval_expression() {
    int32_t left = eval_term();

    while (check(TokenType::PLUS) || check(TokenType::MINUS)) {
        TokenType op = advance().type;
        int32_t right = eval_term();

        if (op == TokenType::PLUS) {
            left += right;
        } else {
            left -= right;
        }
    }

    return left;
}

bool Evaluator::eval_condition() {
    int32_t left = eval_expression();

    if (match(TokenType::EQUAL)) {
        return left == eval_expression();
    }
    if (match(TokenType::NOT_EQUAL)) {
        return left != eval_expression();
    }
    if (match(TokenType::LESS_EQUAL)) {
        return left <= eval_expression();
    }
    if (match(TokenType::GREATER_EQUAL)) {
        return left >= eval_expression();
    }
    if (match(TokenType::LESS)) {
        return left < eval_expression();
    }
    if (match(TokenType::GREATER)) {
        return left > eval_expression();
    }

    return left != 0;
}

} // namespace pbasic
