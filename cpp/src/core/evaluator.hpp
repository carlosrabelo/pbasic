#pragma once

#include <core/math.hpp>
#include <core/program.hpp>
#include <core/token.hpp>
#include <core/variables.hpp>
#include <cstdint>
#include <vector>

namespace pbasic {

class Evaluator {
public:
    Evaluator(const std::vector<Token>& tokens, VariableStore& vars, Program& prog, uint16_t& rand_seed);

    int32_t eval_expression();
    bool eval_condition();

    size_t get_cursor() const { return cursor_; }
    void set_cursor(size_t c) { cursor_ = c; }
    bool is_at_end() const;

private:
    int32_t eval_term();
    int32_t eval_factor();

    const Token& current() const;
    const Token& advance();
    bool match(TokenType type);
    bool check(TokenType type) const;

    const std::vector<Token>& tokens_;
    size_t cursor_{0};
    VariableStore& vars_;
    Program& prog_;
    uint16_t& rand_seed_;
    static const Token s_eof_token;
};

} // namespace pbasic
