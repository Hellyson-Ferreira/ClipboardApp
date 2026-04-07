//
//  ClipboardAppApp.swift
//  ClipboardApp
//
//  Created by Hellyson on 07/04/26.
//

import SwiftUI
import AppKit

@main
struct ClipboardAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // ── Popover ────────────────────────────────────────────────────────
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 480, height: 560)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: ClipboardPanelView())
        self.popover = popover

        // ── Status bar icon ────────────────────────────────────────────────
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: "Clipboard")
            button.action = #selector(handleStatusItemClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        // ── Global hotkey (⌘⇧V) ───────────────────────────────────────────
        HotkeyManager.shared.register()
        HotkeyManager.shared.onActivate = { [weak self] in
            self?.togglePopover()
        }

        // ── Notifications ─────────────────────────────────────────────────
        NotificationCenter.default.addObserver(
            forName: .closePanelNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.popover?.performClose(nil)
        }

        NotificationCenter.default.addObserver(
            forName: .showSettingsNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showSettings()
        }

        NotificationCenter.default.addObserver(
            forName: .togglePinPanelNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePinToggle()
        }
    }

    // MARK: - Pin panel

    private func handlePinToggle() {
        guard let popover else { return }
        if PanelState.shared.isPinned {
            popover.behavior = .applicationDefined
        } else {
            popover.behavior = .transient
            // If panel was pinned and is now floating as a window, re-attach it
            if popover.isDetached {
                popover.performClose(nil)
            }
        }
    }

    // MARK: - Status item click

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: NSLocalizedString("Settings…", comment: ""),
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: NSLocalizedString("Quit ClipboardApp", comment: ""),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        // Pattern padrão: atribui menu, dispara clique, remove logo após
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openSettingsFromMenu() {
        showSettings()
    }

    // MARK: - Popover

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Settings window

    private func showSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: controller)
            window.title = "ClipboardApp — Settings"
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 340, height: window.frame.height))
            settingsWindow = window
        }
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
