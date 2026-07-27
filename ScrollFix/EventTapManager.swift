import ApplicationServices

final class EventTapManager {
    private(set) var isInstalled = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var shouldProcessEvents = false

    @discardableResult
    func start() -> Bool {
        if isInstalled {
            shouldProcessEvents = true
            return true
        }

        guard AXIsProcessTrusted() else {
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
            return false
        }

        guard let newSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            newTap,
            0
        ) else {
            CFMachPortInvalidate(newTap)
            return false
        }

        eventTap = newTap
        runLoopSource = newSource
        shouldProcessEvents = true
        isInstalled = true

        CFRunLoopAddSource(CFRunLoopGetMain(), newSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
        return true
    }

    func stop() {
        shouldProcessEvents = false

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
