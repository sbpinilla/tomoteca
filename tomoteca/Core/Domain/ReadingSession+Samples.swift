//
//  ReadingSession+Samples.swift
//  tomoteca
//

#if DEBUG
import Foundation

extension Array where Element == ReadingSession {

    /// A week of uneven reading, including a day with nothing, for previews and the seeded run.
    static var previewWeek: [ReadingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Minutes read on each of the last seven days, today last. The zero is deliberate:
        // an empty day has to be visible in the chart.
        let minutesPerDay = [18, 32, 0, 45, 21, 27, 24]

        return minutesPerDay.enumerated().compactMap { offset, minutes in
            guard
                minutes > 0,
                let day = calendar.date(byAdding: .day, value: offset - 6, to: today),
                let started = calendar.date(byAdding: .hour, value: 20, to: day)
            else {
                return nil
            }

            return ReadingSession(
                bookID: Book.previewReading.id,
                startedAt: started,
                endedAt: started.addingTimeInterval(TimeInterval(minutes * 60)),
                plannedMinutes: 30,
                actualSeconds: minutes * 60,
                finalPage: 200 + offset * 5
            )
        }
    }
}
#endif
