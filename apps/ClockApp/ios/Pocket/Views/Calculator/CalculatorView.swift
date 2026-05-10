import SwiftUI
import PocketCore

struct CalculatorView: View {
    @StateObject private var state = CalculatorState()
    @Environment(\.horizontalSizeClass) private var hSize

    private let basicKeys: [[Key]] = [
        [.text("AC", .clear), .text("(", .append("(")), .text(")", .append(")")), .text("÷", .append("÷"))],
        [.text("7", .append("7")), .text("8", .append("8")), .text("9", .append("9")), .text("×", .append("×"))],
        [.text("4", .append("4")), .text("5", .append("5")), .text("6", .append("6")), .text("−", .append("-"))],
        [.text("1", .append("1")), .text("2", .append("2")), .text("3", .append("3")), .text("+", .append("+"))],
        [.text("0", .append("0")), .text(".", .append(".")), .text("⌫", .backspace), .text("=", .equals)]
    ]

    private let scientificKeys: [[Key]] = [
        [.text("sin", .append("sin(")), .text("cos", .append("cos(")), .text("tan", .append("tan(")), .text("π", .append("π")), .text("e", .append("e"))],
        [.text("ln", .append("ln(")), .text("log", .append("log(")), .text("√", .append("√")), .text("x²", .append("^2")), .text("x^y", .append("^"))]
    ]

    var body: some View {
        VStack(spacing: 0) {
            display
            keypad
        }
        .navigationTitle("Calculator")
    }

    private var display: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(state.expression.isEmpty ? " " : state.expression)
                .font(.title3).foregroundColor(.secondary)
                .lineLimit(1).truncationMode(.head)
            Text(state.display)
                .font(.system(size: 56, weight: .light))
                .lineLimit(1).truncationMode(.head)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding()
    }

    private var keypad: some View {
        VStack(spacing: 8) {
            if isLandscape {
                ForEach(scientificKeys.indices, id: \.self) { i in row(scientificKeys[i]) }
            }
            ForEach(basicKeys.indices, id: \.self) { i in row(basicKeys[i]) }
        }
        .padding()
    }

    private var isLandscape: Bool {
        // Heuristic: in landscape on iPhone, hSize is .regular
        return hSize == .regular
    }

    private func row(_ keys: [Key]) -> some View {
        HStack(spacing: 8) {
            ForEach(keys.indices, id: \.self) { idx in
                let k = keys[idx]
                Button(action: { handle(k.action) }) {
                    Text(k.label)
                        .font(.title2.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handle(_ a: KeyAction) {
        switch a {
        case .append(let s): state.append(s)
        case .clear:         state.clear()
        case .backspace:     state.backspace()
        case .equals:        state.equals()
        }
    }

    enum KeyAction { case append(String), clear, backspace, equals }
    struct Key { let label: String; let action: KeyAction
        static func text(_ l: String, _ a: KeyAction) -> Key { Key(label: l, action: a) } }
}
