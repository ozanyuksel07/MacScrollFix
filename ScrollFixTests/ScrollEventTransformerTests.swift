import CoreGraphics
import XCTest
@testable import ScrollFix

final class ScrollEventTransformerTests: XCTestCase {
    func testDiscreteScrollInvertsVerticalAndHorizontalDeltas() throws {
        let event = try makeScrollEvent(wheel1: 3, wheel2: -2)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 0)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 30)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -20)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 196_608)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -131_072)

        ScrollEventTransformer.invertDiscreteScrollDeltas(in: event)

        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -3)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), 2)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), -30)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2), 20)
        XCTAssertEqual(
            event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1),
            -196_608
        )
        XCTAssertEqual(
            event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2),
            131_072
        )
    }

    func testContinuousScrollPassesThroughUnchanged() throws {
        let event = try makeScrollEvent(wheel1: 4, wheel2: -5)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 40)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -50)

        ScrollEventTransformer.invertDiscreteScrollDeltas(in: event)

        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), 4)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), -5)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), 40)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2), -50)
    }

    func testContinuousClassificationUsesSystemEventField() throws {
        let event = try makeScrollEvent(wheel1: 1, wheel2: 0)

        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 0)
        XCTAssertFalse(ScrollEventTransformer.isContinuous(event))

        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        XCTAssertTrue(ScrollEventTransformer.isContinuous(event))
    }

    private func makeScrollEvent(wheel1: Int32, wheel2: Int32) throws -> CGEvent {
        try XCTUnwrap(
            CGEvent(
                scrollWheelEvent2Source: nil,
                units: .line,
                wheelCount: 2,
                wheel1: wheel1,
                wheel2: wheel2,
                wheel3: 0
            )
        )
    }
}
