import SwiftUI
import PhotosUI
import DriftCore

struct PhotoGridEditor: View {
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading) {
            PhotosPicker(selection: $selection, maxSelectionCount: 6, matching: .images) {
                Label("Pick up to 6 photos", systemImage: "photo.on.rectangle")
            }
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3)) {
                ForEach(0..<6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.tertiary)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(Text("\(i+1)").foregroundStyle(.secondary))
                }
            }
        }
    }
}
