//
//  SessionDurationSheet.swift
//  tomoteca
//

import SwiftUI

/// Picks how long the session will last before starting it.
struct SessionDurationSheet: View {

    let book: Book
    let onStart: (Int) -> Void

    @State private var minutes = ReadingSessionViewModel.offeredMinutes[1]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                TMText(.sessionNewTitle, style: .title)
                TMText(verbatim: book.title, style: .footnote, color: AppColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                TMText(.sessionDuration, style: .footnote, color: AppColor.textSecondary)

                TMSegmentedPicker(
                    options: ReadingSessionViewModel.offeredMinutes,
                    title: { $0 == 0 ? .sessionDurationFree : .sessionDurationMinutes($0) },
                    selection: $minutes
                )
            }

            TMButton(title: .sessionBegin) { onStart(minutes) }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
    }
}

#if DEBUG
struct SessionDurationSheet_Previews: PreviewProvider {
    static var previews: some View {
        SessionDurationSheet(book: .previewReading) { _ in }
    }
}
#endif
