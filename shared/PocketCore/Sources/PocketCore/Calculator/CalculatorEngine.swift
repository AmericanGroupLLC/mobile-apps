// CalculatorEngine — pure-Swift expression evaluator using shunting-yard.
// Supports: + - × ÷ % ( ) sin cos tan log ln √ x² x^y π e
// Returns .number on success, .error otherwise.
import Foundation

public enum CalcResult: Equatable {
    case number(Double)
    case error(String)
}

public enum CalculatorEngine {
    /// Evaluate the given infix expression string.
    /// Whitespace is ignored. Operators accepted: + - * / × ÷ % ^
    /// Functions: sin cos tan asin acos atan log ln sqrt
    /// Constants: pi π e
    /// Unary minus accepted at start or after another operator/(.
    public static func evaluate(_ expression: String) -> CalcResult {
        do {
            let tokens = try tokenize(expression)
            let rpn = try toRPN(tokens)
            let value = try evalRPN(rpn)
            if value.isNaN { return .error("Not a number") }
            if value.isInfinite { return .error("Overflow") }
            return .number(value)
        } catch let e as CalcError {
            return .error(e.message)
        } catch {
            return .error("Invalid expression")
        }
    }

    // MARK: - Tokenizer

    private enum Token: Equatable {
        case number(Double)
        case op(String)         // + - * / ^ %
        case fn(String)         // sin cos … sqrt
        case lparen, rparen
        case unaryMinus
    }

    private struct CalcError: Error { let message: String }

    private static func tokenize(_ raw: String) throws -> [Token] {
        var tokens: [Token] = []
        let normalized = raw
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "√", with: "sqrt")
            .replacingOccurrences(of: "π", with: "pi")
        let chars = Array(normalized)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace { i += 1; continue }
            if c.isNumber || c == "." {
                var s = ""
                while i < chars.count, chars[i].isNumber || chars[i] == "." {
                    s.append(chars[i]); i += 1
                }
                guard let d = Double(s) else { throw CalcError(message: "Bad number \(s)") }
                tokens.append(.number(d))
                continue
            }
            if c.isLetter {
                var s = ""
                while i < chars.count, chars[i].isLetter {
                    s.append(chars[i]); i += 1
                }
                let lower = s.lowercased()
                switch lower {
                case "pi":  tokens.append(.number(.pi))
                case "e":   tokens.append(.number(M_E))
                case "sin", "cos", "tan", "asin", "acos", "atan", "log", "ln", "sqrt":
                    tokens.append(.fn(lower))
                default: throw CalcError(message: "Unknown identifier \(lower)")
                }
                continue
            }
            switch c {
            case "(":
                tokens.append(.lparen)
            case ")":
                tokens.append(.rparen)
            case "+":
                tokens.append(.op("+"))
            case "-":
                if isUnaryContext(prev: tokens.last) {
                    tokens.append(.unaryMinus)
                } else {
                    tokens.append(.op("-"))
                }
            case "*":
                tokens.append(.op("*"))
            case "/":
                tokens.append(.op("/"))
            case "^":
                tokens.append(.op("^"))
            case "%":
                tokens.append(.op("%"))
            default:
                throw CalcError(message: "Unexpected '\(c)'")
            }
            i += 1
        }
        return tokens
    }

    private static func isUnaryContext(prev: Token?) -> Bool {
        guard let prev else { return true }
        switch prev {
        case .op, .lparen, .unaryMinus, .fn: return true
        default: return false
        }
    }

    // MARK: - Shunting yard

    private static func precedence(_ op: String) -> Int {
        switch op {
        case "+", "-": return 1
        case "*", "/", "%": return 2
        case "^": return 3
        default: return 0
        }
    }

    private static func isRightAssoc(_ op: String) -> Bool { op == "^" }

    private static func toRPN(_ tokens: [Token]) throws -> [Token] {
        var out: [Token] = []
        var stack: [Token] = []
        for tok in tokens {
            switch tok {
            case .number:
                out.append(tok)
            case .fn:
                stack.append(tok)
            case .unaryMinus:
                stack.append(tok)
            case .op(let o):
                while let top = stack.last {
                    if case .op(let topOp) = top {
                        let p = precedence(o), tp = precedence(topOp)
                        if (tp > p) || (tp == p && !isRightAssoc(o)) {
                            out.append(stack.removeLast())
                            continue
                        }
                        break
                    } else if case .unaryMinus = top {
                        // unary minus has very high precedence, drain it
                        out.append(stack.removeLast())
                    } else if case .fn = top {
                        out.append(stack.removeLast())
                    } else {
                        break
                    }
                }
                stack.append(tok)
            case .lparen:
                stack.append(tok)
            case .rparen:
                var found = false
                while let top = stack.last {
                    if case .lparen = top {
                        stack.removeLast()
                        found = true
                        break
                    }
                    out.append(stack.removeLast())
                }
                if !found { throw CalcError(message: "Mismatched parens") }
                if let top = stack.last, case .fn = top {
                    out.append(stack.removeLast())
                }
            }
        }
        while let top = stack.popLast() {
            if case .lparen = top { throw CalcError(message: "Mismatched parens") }
            if case .rparen = top { throw CalcError(message: "Mismatched parens") }
            out.append(top)
        }
        return out
    }

    private static func evalRPN(_ rpn: [Token]) throws -> Double {
        var st: [Double] = []
        for tok in rpn {
            switch tok {
            case .number(let d):
                st.append(d)
            case .unaryMinus:
                guard let a = st.popLast() else { throw CalcError(message: "Bad unary") }
                st.append(-a)
            case .op(let o):
                guard let b = st.popLast(), let a = st.popLast() else {
                    throw CalcError(message: "Bad operands for \(o)")
                }
                switch o {
                case "+": st.append(a + b)
                case "-": st.append(a - b)
                case "*": st.append(a * b)
                case "/":
                    if b == 0 { throw CalcError(message: "Divide by zero") }
                    st.append(a / b)
                case "%":
                    if b == 0 { throw CalcError(message: "Divide by zero") }
                    st.append(a.truncatingRemainder(dividingBy: b))
                case "^": st.append(pow(a, b))
                default: throw CalcError(message: "Unknown op \(o)")
                }
            case .fn(let f):
                guard let a = st.popLast() else { throw CalcError(message: "Bad arg for \(f)") }
                switch f {
                case "sin":  st.append(sin(a))
                case "cos":  st.append(cos(a))
                case "tan":  st.append(tan(a))
                case "asin": st.append(asin(a))
                case "acos": st.append(acos(a))
                case "atan": st.append(atan(a))
                case "log":  st.append(log10(a))
                case "ln":   st.append(log(a))
                case "sqrt":
                    if a < 0 { throw CalcError(message: "Sqrt of negative") }
                    st.append(sqrt(a))
                default: throw CalcError(message: "Unknown fn \(f)")
                }
            case .lparen, .rparen:
                throw CalcError(message: "Stray paren")
            }
        }
        guard st.count == 1, let r = st.first else { throw CalcError(message: "Invalid expression") }
        return r
    }
}
