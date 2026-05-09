// CalculatorState — observable state for the calculator UI.
// Holds the current expression buffer + last 10 results.
import Foundation
import Combine

@MainActor
public final class CalculatorState: ObservableObject {
    @Published public private(set) var expression: String = ""
    @Published public private(set) var display: String = "0"
    @Published public private(set) var history: [String] = []  // "1+2 = 3" entries

    public init() {}

    public func append(_ s: String) {
        expression += s
        recomputeDisplayPreview()
    }

    public func clear() {
        expression = ""
        display = "0"
    }

    public func backspace() {
        guard !expression.isEmpty else { return }
        expression.removeLast()
        recomputeDisplayPreview()
    }

    public func equals() {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch CalculatorEngine.evaluate(expression) {
        case .number(let n):
            let formatted = format(n)
            history.insert("\(expression) = \(formatted)", at: 0)
            if history.count > 10 { history.removeLast(history.count - 10) }
            display = formatted
            expression = formatted
        case .error(let msg):
            display = msg
        }
    }

    private func recomputeDisplayPreview() {
        if expression.isEmpty { display = "0"; return }
        switch CalculatorEngine.evaluate(expression) {
        case .number(let n): display = format(n)
        case .error: display = expression  // show raw while typing
        }
    }

    private func format(_ n: Double) -> String {
        if n == n.rounded() && abs(n) < 1e15 {
            return String(format: "%.0f", n)
        }
        return String(n)
    }
}
