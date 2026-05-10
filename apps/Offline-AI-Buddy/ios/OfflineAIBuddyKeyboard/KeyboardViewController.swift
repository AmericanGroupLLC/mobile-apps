import UIKit

/// `OfflineAIBuddyKeyboard` system Keyboard Extension. Renders a
/// minimal QWERTY + a 3-suggestion candidate strip. Talks to the main
/// app via App Group + Darwin notifications. See `KEYBOARD.md`.
class KeyboardViewController: UIInputViewController {

    private let bridge = KeyboardBridgeClient()
    private var suggestionButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCandidateStrip()
        bridge.onReply = { [weak self] suggestions in
            DispatchQueue.main.async { self?.render(suggestions) }
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        bridge.requestSuggestions(forContext: context)
    }

    // MARK: - UI

    private func setupCandidateStrip() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        for _ in 0..<3 {
            let b = UIButton(type: .system)
            b.titleLabel?.font = .systemFont(ofSize: 14)
            b.setTitleColor(.label, for: .normal)
            b.backgroundColor = .secondarySystemBackground
            b.layer.cornerRadius = 6
            b.addTarget(self, action: #selector(tapSuggestion(_:)), for: .touchUpInside)
            suggestionButtons.append(b)
            stack.addArrangedSubview(b)
        }

        let openMain = UIButton(type: .system)
        openMain.setTitle("Open Offline AI Buddy", for: .normal)
        openMain.titleLabel?.font = .systemFont(ofSize: 12)
        openMain.addTarget(self, action: #selector(openHostApp), for: .touchUpInside)
        view.addSubview(openMain)
        openMain.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            stack.heightAnchor.constraint(equalToConstant: 36),

            openMain.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 8),
            openMain.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openMain.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8),
        ])
    }

    private func render(_ suggestions: [String]) {
        for (i, b) in suggestionButtons.enumerated() {
            let title = i < suggestions.count ? suggestions[i] : ""
            b.setTitle(title, for: .normal)
            b.isEnabled = !title.isEmpty
        }
    }

    // MARK: - Actions

    @objc private func tapSuggestion(_ sender: UIButton) {
        if let s = sender.titleLabel?.text, !s.isEmpty {
            textDocumentProxy.insertText(s)
        }
    }

    /// Tries to open the host app via custom URL scheme. iOS extensions
    /// can do this only on a user-initiated tap.
    @objc private func openHostApp() {
        if let url = URL(string: "offlineaibuddy://") {
            extensionContext?.open(url, completionHandler: nil)
        }
    }
}
