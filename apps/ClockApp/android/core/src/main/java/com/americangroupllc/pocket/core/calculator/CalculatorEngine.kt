package com.americangroupllc.pocket.core.calculator

import kotlin.math.*

sealed class CalcResult {
    data class Number(val value: Double) : CalcResult()
    data class Error(val message: String) : CalcResult()
}

/**
 * Pure-Kotlin shunting-yard expression evaluator.
 * Supports: + - * / × ÷ % ^ ( ) sin cos tan asin acos atan log ln sqrt √ pi π e
 */
object CalculatorEngine {

    fun evaluate(expression: String): CalcResult {
        return try {
            val tokens = tokenize(expression)
            val rpn = toRPN(tokens)
            val v = evalRPN(rpn)
            when {
                v.isNaN() -> CalcResult.Error("Not a number")
                v.isInfinite() -> CalcResult.Error("Overflow")
                else -> CalcResult.Number(v)
            }
        } catch (e: CalcException) {
            CalcResult.Error(e.message ?: "Invalid expression")
        }
    }

    private class CalcException(message: String) : RuntimeException(message)

    private sealed class Token {
        data class Num(val v: Double) : Token()
        data class Op(val s: String) : Token()
        data class Fn(val s: String) : Token()
        object L : Token()
        object R : Token()
        object UnaryMinus : Token()
    }

    private fun tokenize(raw: String): List<Token> {
        val s = raw
            .replace("×", "*")
            .replace("÷", "/")
            .replace("−", "-")
            .replace("√", "sqrt")
            .replace("π", "pi")
        val out = mutableListOf<Token>()
        var i = 0
        while (i < s.length) {
            val c = s[i]
            if (c.isWhitespace()) { i++; continue }
            if (c.isDigit() || c == '.') {
                val sb = StringBuilder()
                while (i < s.length && (s[i].isDigit() || s[i] == '.')) {
                    sb.append(s[i]); i++
                }
                out.add(Token.Num(sb.toString().toDoubleOrNull() ?: throw CalcException("Bad number")))
                continue
            }
            if (c.isLetter()) {
                val sb = StringBuilder()
                while (i < s.length && s[i].isLetter()) {
                    sb.append(s[i]); i++
                }
                when (val name = sb.toString().lowercase()) {
                    "pi" -> out.add(Token.Num(PI))
                    "e"  -> out.add(Token.Num(E))
                    "sin", "cos", "tan", "asin", "acos", "atan", "log", "ln", "sqrt" ->
                        out.add(Token.Fn(name))
                    else -> throw CalcException("Unknown identifier $name")
                }
                continue
            }
            when (c) {
                '(' -> out.add(Token.L)
                ')' -> out.add(Token.R)
                '+' -> out.add(Token.Op("+"))
                '-' -> if (isUnaryContext(out.lastOrNull())) out.add(Token.UnaryMinus) else out.add(Token.Op("-"))
                '*' -> out.add(Token.Op("*"))
                '/' -> out.add(Token.Op("/"))
                '^' -> out.add(Token.Op("^"))
                '%' -> out.add(Token.Op("%"))
                else -> throw CalcException("Unexpected '$c'")
            }
            i++
        }
        return out
    }

    private fun isUnaryContext(prev: Token?): Boolean {
        if (prev == null) return true
        return prev is Token.Op || prev is Token.L || prev is Token.UnaryMinus || prev is Token.Fn
    }

    private fun precedence(op: String) = when (op) {
        "+", "-" -> 1
        "*", "/", "%" -> 2
        "^" -> 3
        else -> 0
    }

    private fun isRightAssoc(op: String) = op == "^"

    private fun toRPN(tokens: List<Token>): List<Token> {
        val out = mutableListOf<Token>()
        val stack = ArrayDeque<Token>()
        for (tok in tokens) {
            when (tok) {
                is Token.Num -> out.add(tok)
                is Token.Fn -> stack.addLast(tok)
                is Token.UnaryMinus -> stack.addLast(tok)
                is Token.Op -> {
                    while (true) {
                        val top = stack.lastOrNull() ?: break
                        when (top) {
                            is Token.Op -> {
                                val tp = precedence(top.s)
                                val p = precedence(tok.s)
                                if (tp > p || (tp == p && !isRightAssoc(tok.s))) {
                                    out.add(stack.removeLast())
                                    continue
                                } else break
                            }
                            is Token.UnaryMinus, is Token.Fn -> out.add(stack.removeLast())
                            else -> break
                        }
                    }
                    stack.addLast(tok)
                }
                Token.L -> stack.addLast(tok)
                Token.R -> {
                    var found = false
                    while (stack.isNotEmpty()) {
                        val top = stack.removeLast()
                        if (top is Token.L) { found = true; break }
                        out.add(top)
                    }
                    if (!found) throw CalcException("Mismatched parens")
                    val maybeFn = stack.lastOrNull()
                    if (maybeFn is Token.Fn) out.add(stack.removeLast())
                }
            }
        }
        while (stack.isNotEmpty()) {
            val t = stack.removeLast()
            if (t is Token.L || t is Token.R) throw CalcException("Mismatched parens")
            out.add(t)
        }
        return out
    }

    private fun evalRPN(rpn: List<Token>): Double {
        val st = ArrayDeque<Double>()
        for (tok in rpn) {
            when (tok) {
                is Token.Num -> st.addLast(tok.v)
                is Token.UnaryMinus -> {
                    val a = st.removeLastOrNull() ?: throw CalcException("Bad unary")
                    st.addLast(-a)
                }
                is Token.Op -> {
                    val b = st.removeLastOrNull() ?: throw CalcException("Bad op")
                    val a = st.removeLastOrNull() ?: throw CalcException("Bad op")
                    val r = when (tok.s) {
                        "+" -> a + b
                        "-" -> a - b
                        "*" -> a * b
                        "/" -> { if (b == 0.0) throw CalcException("Divide by zero"); a / b }
                        "%" -> { if (b == 0.0) throw CalcException("Divide by zero"); a % b }
                        "^" -> a.pow(b)
                        else -> throw CalcException("Unknown op ${tok.s}")
                    }
                    st.addLast(r)
                }
                is Token.Fn -> {
                    val a = st.removeLastOrNull() ?: throw CalcException("Bad fn")
                    val r = when (tok.s) {
                        "sin" -> sin(a); "cos" -> cos(a); "tan" -> tan(a)
                        "asin" -> asin(a); "acos" -> acos(a); "atan" -> atan(a)
                        "log" -> log10(a); "ln" -> ln(a)
                        "sqrt" -> { if (a < 0) throw CalcException("Sqrt of negative"); sqrt(a) }
                        else -> throw CalcException("Unknown fn ${tok.s}")
                    }
                    st.addLast(r)
                }
                else -> throw CalcException("Stray paren")
            }
        }
        if (st.size != 1) throw CalcException("Invalid expression")
        return st.last()
    }
}
