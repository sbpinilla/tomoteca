//
//  StoredSessionTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

struct StoredSessionTests {

    private static let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func planned(minutes: Int, accumulated: TimeInterval = 0, running: Bool = true) -> StoredSession {
        StoredSession(
            bookID: UUID(),
            plannedMinutes: minutes,
            startedAt: Self.start,
            accumulated: accumulated,
            segmentStartedAt: running ? Self.start : nil
        )
    }

    // MARK: isFree

    @Test("Zero planned minutes is what makes a session free")
    func zeroMeansFree() {
        #expect(planned(minutes: 0).isFree)
        #expect(planned(minutes: 15).isFree == false)
    }

    // MARK: remaining / isExpired

    @Test("A free session has nothing remaining, at any point")
    func freeSessionHasNoRemaining() {
        let session = planned(minutes: 0)

        #expect(session.remaining(at: Self.start) == 0)
        #expect(session.remaining(at: Self.start.addingTimeInterval(60 * 60 * 5)) == 0)
    }

    @Test("A free session never expires, however long it runs")
    func freeSessionNeverExpires() {
        let session = planned(minutes: 0)

        #expect(session.isExpired(at: Self.start) == false)
        #expect(session.isExpired(at: Self.start.addingTimeInterval(60 * 60 * 10)) == false)
    }

    @Test("A planned session still expires exactly as before")
    func plannedSessionStillExpires() {
        let session = planned(minutes: 10)

        #expect(session.isExpired(at: Self.start.addingTimeInterval(9 * 60)) == false)
        #expect(session.isExpired(at: Self.start.addingTimeInterval(10 * 60)))
    }

    // MARK: isStale

    @Test("A free session left running goes stale after 24 hours, same as a planned one")
    func freeSessionGoesStale() {
        let session = planned(minutes: 0)

        #expect(session.isStale(at: Self.start.addingTimeInterval(23 * 60 * 60)) == false)
        #expect(session.isStale(at: Self.start.addingTimeInterval(25 * 60 * 60)))
    }

    @Test("A paused free session never goes stale")
    func pausedFreeSessionNeverGoesStale() {
        let session = planned(minutes: 0, accumulated: 300, running: false)

        #expect(session.isStale(at: Self.start.addingTimeInterval(48 * 60 * 60)) == false)
    }

    // MARK: elapsed (unaffected by isFree, but worth pinning down)

    @Test("Elapsed time for a free session is exactly what it counts up from")
    func freeSessionElapsed() {
        let session = planned(minutes: 0)

        #expect(session.elapsed(at: Self.start.addingTimeInterval(754)) == 754)
    }
}
