import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = false
    @State private var loginError: String? = nil
    @State private var settings = AppSettings.shared

    private let hotkey = HotkeyManager.shared.currentHotkey

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.15)
            settingsList
        }
        .frame(width: 340)
        .background(Color(hex: "#161616"))
        .preferredColorScheme(.dark)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#30D158"))
            VStack(alignment: .leading, spacing: 1) {
                Text("ClipboardApp")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("Settings")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Settings list

    private var settingsList: some View {
        VStack(spacing: 0) {
            sectionHeader("General")
            settingRow(
                icon: "power",
                iconColor: Color(hex: "#30D158"),
                title: "Launch at Login",
                subtitle: "Open ClipboardApp automatically when you log in"
            ) {
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(Color(hex: "#30D158"))
                    .onChange(of: launchAtLogin, perform: applyLoginItem)
            }

            if let err = loginError {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#FF453A"))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            settingRow(
                icon: "tray.full",
                iconColor: Color(hex: "#FF9F0A"),
                title: "Max saved items",
                subtitle: "Oldest unpinned clips are removed when the limit is reached"
            ) {
                maxItemsStepper
            }

            Divider().opacity(0.08).padding(.horizontal, 16)

            sectionHeader("Keyboard")
            settingRow(
                icon: "keyboard",
                iconColor: Color(hex: "#0A84FF"),
                title: "Open ClipboardApp",
                subtitle: "Global shortcut to toggle the panel"
            ) {
                Text(hotkey.display)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }

            Divider().opacity(0.08).padding(.horizontal, 16)

            sectionHeader("About")
            settingRow(
                icon: "info.circle",
                iconColor: .white.opacity(0.4),
                title: "Version",
                subtitle: nil
            ) {
                Text(appVersion)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Components

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(LocalizedStringKey(title))
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    @ViewBuilder
    private func settingRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
        @ViewBuilder control: () -> some View
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.88))
                if let sub = subtitle {
                    Text(LocalizedStringKey(sub))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                }
            }

            Spacer()
            control()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Max items stepper

    private var maxItemsStepper: some View {
        HStack(spacing: 6) {
            Button {
                settings.maxItems = max(50, settings.maxItems - 50)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)

            Text("\(settings.maxItems)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .frame(minWidth: 36)
                .multilineTextAlignment(.center)

            Button {
                settings.maxItems = min(5000, settings.maxItems + 50)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func applyLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            launchAtLogin = !enabled
        }
    }
}

#Preview {
    SettingsView()
}
