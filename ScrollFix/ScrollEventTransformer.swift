import CoreGraphics

enum ScrollEventTransformer {
    private static let deltaFields: [CGEventField] = [
        .scrollWheelEventDeltaAxis1,
        .scrollWheelEventDeltaAxis2,
        .scrollWheelEventDeltaAxis3,
        .scrollWheelEventPointDeltaAxis1,
        .scrollWheelEventPointDeltaAxis2,
        .scrollWheelEventPointDeltaAxis3,
        .scrollWheelEventFixedPtDeltaAxis1,
        .scrollWheelEventFixedPtDeltaAxis2,
        .scrollWheelEventFixedPtDeltaAxis3
    ]

    static func isContinuous(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
    }

    static func invertDiscreteScrollDeltas(in event: CGEvent) {
        // Trackpad ve bazı Magic Mouse olayları continuous gelir; bunlara dokunulmaz.
        guard !isContinuous(event) else { return }

        // Core Graphics, aynı eksenin line/point/fixed-point alanlarını bir alan
        // yazıldığında birlikte güncelleyebilir. Bu nedenle önce tüm özgün değerleri
        // alır, sonra yazarız; aksi halde daha önce ters çevrilmiş bir değeri ikinci
        // kez tersine çevirme riski oluşur.
        let originalValues = deltaFields.map {
            event.getIntegerValueField($0)
        }

        for (field, value) in zip(deltaFields, originalValues) {
            // Gerçek scroll deltaları bu uç değere ulaşmaz; taşmayı yine de güvenle önle.
            guard value != Int64.min else { continue }
            event.setIntegerValueField(field, value: -value)
        }
    }
}
