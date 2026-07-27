import ApplicationServices
import Foundation
import OSLog

final class EventTapManager {
    private(set) var isInstalled = false

    var isOperational: Bool {
        guard
            shouldProcessEvents,
            isInstalled,
            let eventTap,
            CFMachPortIsValid(eventTap)
        else {
            return false
        }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var shouldProcessEvents = false
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ozanyuksel.MacScrollFix",
        category: "EventTap"
    )

    @discardableResult
    func start() -> Bool {
        shouldProcessEvents = true

        if isOperational {
            return true
        }

        // Kurulu görünen fakat sistem tarafından geçersiz hâle gelmiş bir tap
        // varsa önce tamamen temizleriz. Böylece aynı anda ikinci tap oluşmaz.
        if isInstalled || eventTap != nil || runLoopSource != nil {
            tearDown()
        }

        guard AXIsProcessTrusted() else {
            logger.notice("Erişilebilirlik izni olmadığı için event tap başlatılmadı.")
            return false
        }

        let eventMask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<EventTapManager>
                .fromOpaque(userInfo)
                .takeUnretainedValue()

            return manager.handle(type: type, event: event)
        }

        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            logger.error("CGEventTap oluşturulamadı.")
            return false
        }

        guard let newSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            newTap,
            0
        ) else {
            CFMachPortInvalidate(newTap)
            logger.error("Event tap run loop kaynağı oluşturulamadı.")
            return false
        }

        eventTap = newTap
        runLoopSource = newSource
        shouldProcessEvents = true
        isInstalled = true

        CFRunLoopAddSource(CFRunLoopGetMain(), newSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)

        guard isOperational else {
            logger.error("Event tap oluşturuldu ancak etkinleştirilemedi.")
            tearDown()
            return false
        }

        logger.info("Scroll event tap etkinleştirildi.")
        return true
    }

    func stop() {
        shouldProcessEvents = false
        tearDown()
    }

    @discardableResult
    func restoreIfNeeded() -> Bool {
        guard shouldProcessEvents else {
            return false
        }
        if isOperational {
            return true
        }

        logger.notice("Event tap sağlıksız; güvenli biçimde yeniden kuruluyor.")
        return start()
    }

    private func tearDown() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }

        runLoopSource = nil
        eventTap = nil
        isInstalled = false
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if shouldProcessEvents, let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                if !CGEvent.tapIsEnabled(tap: eventTap) {
                    DispatchQueue.main.async { [weak self] in
                        _ = self?.restoreIfNeeded()
                    }
                }
            }
            return Unmanaged.passUnretained(event)
        }

        guard shouldProcessEvents, type == .scrollWheel else {
            return Unmanaged.passUnretained(event)
        }

        ScrollEventTransformer.invertDiscreteScrollDeltas(in: event)
        return Unmanaged.passUnretained(event)
    }

    deinit {
        stop()
    }
}
