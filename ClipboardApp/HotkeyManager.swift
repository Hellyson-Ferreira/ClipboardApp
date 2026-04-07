import Carbon.HIToolbox
import AppKit

// MARK: - Hotkey definition

struct Hotkey: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let display: String

    static let defaultHotkey = Hotkey(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | shiftKey),
        display: "⌘⇧V"
    )
}

// MARK: - Manager

final class HotkeyManager {
    static let shared = HotkeyManager()
    var onActivate: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private(set) var currentHotkey: Hotkey = .defaultHotkey

    private init() {}

    // MARK: - Register / Unregister

    func register(_ hotkey: Hotkey = .defaultHotkey) {
        unregister()
        currentHotkey = hotkey

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, _, userData) -> OSStatus in
                guard let ptr = userData else { return OSStatus(eventNotHandledErr) }
                let mgr = Unmanaged<HotkeyManager>.fromOpaque(ptr).takeUnretainedValue()
                mgr.onActivate?()
                return noErr
            },
            1, &spec, selfPtr, &handlerRef
        )

        var hkID = EventHotKeyID(signature: OSType(0x434C4950), id: 1)
        RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiers,
            hkID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef   { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let ref = handlerRef  { RemoveEventHandler(ref);    handlerRef = nil }
    }
}
