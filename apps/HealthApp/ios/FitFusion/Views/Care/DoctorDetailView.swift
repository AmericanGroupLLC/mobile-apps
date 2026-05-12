import SwiftUI
import FitFusionCore

/// Detail screen for a single NPPES provider. Supports favoriting (writes
/// to PHIProviderEntity in PHIStore so it's encrypted at rest). Booking
/// flow is deferred to week 4 — see ComingSoon link at the bottom.
struct DoctorDetailView: View {

    let provider: DoctorFinderView.Provider

    @State private var favorited = false
    private let tint = CarePlusPalette.careBlue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CarePlusSpacing.md) {
                header

                if let phone = provider.phone, !phone.isEmpty {
                    Link(destination: URL(string: "tel://\(phone)")!) {
                        Label(phone, systemImage: "phone.fill")
                            .frame(maxWidth: .infinity).padding()
                            .background(CarePlusPalette.surfaceElevated,
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                if let addr = provider.address_line, !addr.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "mappin.and.ellipse").foregroundStyle(tint)
                        Text(addr)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CarePlusPalette.surfaceElevated,
                                in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    favorite()
                } label: {
                    Label(favorited ? "Saved" : "Save to favorites",
                          systemImage: favorited ? "star.fill" : "star")
                        .frame(maxWidth: .infinity).padding()
                        .background(tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .disabled(favorited)

                NavigationLink {
                    ComingSoon(title: "Book appointment", symbol: "calendar.badge.plus",
                               tint: tint, etaWeek: 4)
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus").foregroundStyle(tint)
                        Text("Book an appointment")
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(CarePlusPalette.surfaceElevated,
                                in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)

                Text("Listing data: NPPES public registry. Booking via Ribbon Health (v1.1).")
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(CarePlusSpacing.lg)
        }
        .navigationTitle(provider.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(provider.name).font(.title2.bold())
            if let sp = provider.specialty {
                Text(sp).font(.subheadline).foregroundStyle(.secondary)
            }
            Text("NPI: \(provider.npi)").font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private func favorite() {
        _ = PHIStore.shared.favoriteProvider(
            npi: provider.npi, name: provider.name,
            specialty: provider.specialty, phone: provider.phone,
            addressLine: provider.address_line, zip: provider.zip
        )
        favorited = true
    }
}
