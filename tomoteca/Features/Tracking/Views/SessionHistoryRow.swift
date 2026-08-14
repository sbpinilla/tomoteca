//
//  SessionHistoryRow.swift
//  tomoteca
//

import SwiftUI

/// One reading session in the history: which book, and how much of it was read.
///
/// Built like the trunk and in-progress rows — cover, title, author — so the same book looks the
/// same wherever it turns up. The third line is what this screen adds: what that sitting was
/// worth, rather than where the book stands overall.
///
/// Not a button. The session is closed and there is nothing to open.
struct SessionHistoryRow: View {

    let entry: TrackingViewModel.Entry

    var body: some View {
        HStack(spacing: Spacing.md) {
            TMBookCover(data: entry.book.coverImageData, width: 44, height: 62)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                TMText(verbatim: entry.book.title, style: .headline)
                    .lineLimit(1)

                if let author = entry.book.author, !author.isEmpty {
                    TMText(verbatim: author, style: .footnote, color: AppColor.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: Spacing.xs) {
                    date
                    TMText(verbatim: "·", style: .footnote, color: AppColor.textSecondary)
                    TMText(
                        .trackingHistoryPages(entry.pagesRead),
                        style: .footnote,
                        color: AppColor.textSecondary
                    )
                    TMText(verbatim: "·", style: .footnote, color: AppColor.textSecondary)
                    TMText(
                        .trackingMinutes(entry.minutes),
                        style: .footnote,
                        color: AppColor.textSecondary
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
        // Announced as one line — "Sapiens, Yuval Noah Harari, today, 32 pages, 15 minutes" —
        // rather than as five fragments to swipe through.
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("sessionRow")
    }

    /// Today and yesterday are named; anything older gets its date, because "3 days ago" stops
    /// being easier to place than the date itself almost immediately.
    ///
    /// The date goes through `FormatStyle`, so the day and the month land in the order each
    /// language writes them.
    @ViewBuilder
    private var date: some View {
        let calendar = Calendar.current

        if calendar.isDateInToday(entry.date) {
            TMText(.trackingHistoryToday, style: .footnote, color: AppColor.textSecondary)
        } else if calendar.isDateInYesterday(entry.date) {
            TMText(.trackingHistoryYesterday, style: .footnote, color: AppColor.textSecondary)
        } else {
            TMText(
                verbatim: entry.date.formatted(.dateTime.day().month(.abbreviated)),
                style: .footnote,
                color: AppColor.textSecondary
            )
        }
    }
}

#if DEBUG
struct SessionHistoryRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            SessionHistoryRow(
                entry: TrackingViewModel.Entry(
                    id: UUID(),
                    book: .previewReading,
                    date: Date(),
                    pagesRead: 32,
                    minutes: 15
                )
            )

            Divider().overlay(AppColor.borderSubtle)

            SessionHistoryRow(
                entry: TrackingViewModel.Entry(
                    id: UUID(),
                    book: .previewOwned,
                    date: Date().addingTimeInterval(-60 * 60 * 24 * 9),
                    pagesRead: 0,
                    minutes: 3
                )
            )
        }
        .padding(Spacing.md)
        .background(AppColor.surface)
        .previewLayout(.sizeThatFits)
    }
}
#endif
