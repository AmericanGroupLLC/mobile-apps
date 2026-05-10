import SwiftUI
import UserNotifications
import CoreLocation
import AVFoundation

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var page: Int = 0

    var body: some View {
        TabView(selection: $page) {
            welcomePage.tag(0)
            notificationPage.tag(1)
            sensorPermissionsPage.tag(2)
            donePage.tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Text("🪶").font(.system(size: 80))
            Text("Welcome to Pocket").font(.largeTitle).bold()
            Text("Five hand-built tools — Clock, Calculator, Measure, Compass, Level. No account, no tracking by default.")
                .multilineTextAlignment(.center).padding(.horizontal)
            Button("Get started") { withAnimation { page = 1 } }.buttonStyle(.borderedProminent)
        }
    }

    private var notificationPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge").font(.system(size: 70))
            Text("Alarms need notifications").font(.title).bold()
            Text("Allow notifications so your alarms ring on time.")
                .multilineTextAlignment(.center).padding(.horizontal)
            Button("Allow") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                    DispatchQueue.main.async { withAnimation { page = 2 } }
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Skip") { withAnimation { page = 2 } }
        }
    }

    private var sensorPermissionsPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.viewfinder").font(.system(size: 70))
            Text("Camera & Location").font(.title).bold()
            Text("Measure uses the camera. Compass uses location for true heading. Each tool re-asks if needed.")
                .multilineTextAlignment(.center).padding(.horizontal)
            HStack(spacing: 12) {
                Button("Allow camera") { AVCaptureDevice.requestAccess(for: .video) { _ in } }
                Button("Allow location") {
                    let mgr = CLLocationManager()
                    mgr.requestWhenInUseAuthorization()
                }
            }
            Button("Continue") { withAnimation { page = 3 } }.buttonStyle(.borderedProminent)
        }
    }

    private var donePage: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 70)).foregroundColor(.green)
            Text("You're all set").font(.title).bold()
            Button("Open Pocket") { onComplete() }.buttonStyle(.borderedProminent)
        }
    }
}
