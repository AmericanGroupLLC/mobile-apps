import SwiftUI
import FitFusionCore
#if canImport(UIKit)
import UIKit

/// Insurance card sheet — camera/picker → on-device OCR → review → save.
/// Fields land in the PHI Core Data store; raw OCR text lands in Keychain.
struct InsuranceCardSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var result: InsuranceCardOCR.Result?
    @State private var showCamera = false
    @State private var processing = false

    let onSaved: () -> Void

    private let tint = CarePlusPalette.careBlue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable().scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        empty
                    }

                    if processing { ProgressView("Reading card…") }

                    if let r = result {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Detected").font(CarePlusType.titleSM)
                            row("Payer", r.payer)
                            row("Member ID", r.memberId)
                            row("Group #", r.groupNumber)
                            row("BIN", r.bin)
                            row("PCN", r.pcn)
                            row("RxGrp", r.rxGrp)
                        }
                        .padding()
                        .background(CarePlusPalette.surfaceElevated,
                                    in: RoundedRectangle(cornerRadius: 12))

                        Button {
                            save(r)
                        } label: {
                            Text("Save to my profile").bold()
                                .frame(maxWidth: .infinity).padding()
                                .background(tint, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                    }

                    Text("Image and parsed text never leave this device.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .navigationTitle("Insurance card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCamera = true
                    } label: { Label("Snap", systemImage: "camera") }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, source: .camera)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedImage) { _, newImage in
                guard let img = newImage else { return }
                Task { await runOCR(img) }
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.viewfinder")
                .font(.system(size: 48)).foregroundStyle(tint)
            Text("Snap the front of your insurance card.").font(.subheadline)
            Button {
                showCamera = true
            } label: {
                Label("Open camera", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity).padding()
                    .background(tint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity).padding()
        .background(CarePlusPalette.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 12))
    }

    private func row(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "—").font(.body.monospaced())
        }
        .padding(.vertical, 4)
    }

    @MainActor
    private func runOCR(_ image: UIImage) async {
        processing = true; defer { processing = false }
        let r = await InsuranceCardOCR.shared.parse(image: image)
        self.result = r
    }

    private func save(_ r: InsuranceCardOCR.Result) {
        #if canImport(Security)
        KeychainStore.shared.set(r.rawText,
                                 service: KeychainStore.Service.insurance,
                                 account: "raw_text")
        #endif
        _ = PHIStore.shared.saveInsuranceCard(
            payer: r.payer, memberId: r.memberId, groupNumber: r.groupNumber,
            bin: r.bin, pcn: r.pcn, rxGrp: r.rxGrp
        )
        onSaved()
        dismiss()
    }
}

// MARK: - UIKit camera bridge

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var source: UIImagePickerController.SourceType = .camera

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = UIImagePickerController.isSourceTypeAvailable(source) ? source : .photoLibrary
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
