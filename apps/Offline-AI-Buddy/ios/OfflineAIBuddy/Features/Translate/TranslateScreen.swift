import SwiftUI
import BuddyAICore

struct TranslateScreen: View {
    @EnvironmentObject private var llama: LlamaService
    @State private var src: Language = .en
    @State private var dst: Language = .hi
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var loading = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Picker("From", selection: $src) {
                    ForEach(Language.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Image(systemName: "arrow.right")
                Picker("To", selection: $dst) {
                    ForEach(Language.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }
            .padding(.horizontal)

            TextEditor(text: $input)
                .frame(minHeight: 80)
                .padding(.horizontal)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.gray.opacity(0.3)))

            if TranslateOrchestrator.isBetaPair(src: src, dst: dst) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Beta translation — quality may vary.")
                    Spacer()
                    if let url = TranslateOrchestrator.googleTranslateURL(src: src, dst: dst, text: input) {
                        Link("Google Translate", destination: url).font(.footnote)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.orange)
                .padding(.horizontal)
            }

            Button(loading ? "Translating…" : "Translate") {
                Task { await translate() }
            }
            .disabled(input.isEmpty || loading)
            .buttonStyle(.borderedProminent)

            ScrollView {
                Text(output).padding()
            }
        }
        .navigationTitle("Translate")
    }

    private func translate() async {
        loading = true
        output = ""
        defer { loading = false }
        let stream = llama.generate(
            kind: .translate,
            language: dst,
            isKidSafe: false,
            history: [],
            userInput: input,
            translateSrc: src,
            translateDst: dst
        )
        var collected = ""
        for await t in stream { collected += t.text; if t.isLast { break } }
        output = collected.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
