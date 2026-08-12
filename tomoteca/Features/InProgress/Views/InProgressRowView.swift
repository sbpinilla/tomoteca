//
//  InProgressRowView.swift
//  tomoteca
//

import SwiftUI

/// A book on this shelf: cover, title, author and how far along it is.
///
/// Its own row rather than the trunk's, because every book here shares the same status — a
/// chip repeating "Reading" four times would say nothing — and the progress bar earns that space.
struct InProgressRowView: View {

    let book: Book

    var body: some View {
        HStack(spacing: Spacing.md) {
            TMBookCover(data: book.coverImageData, width: 44, height: 62)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                TMText(verbatim: book.title, style: .headline)

                if let author = book.author, !author.isEmpty {
                    TMText(verbatim: author, style: .footnote, color: AppColor.textSecondary)
                }

                HStack(spacing: Spacing.sm) {
                    TMProgressBar(value: book.progress, color: AppColor.Status.reading)
                    TMText(verbatim: formattedProgress, style: .footnote, color: AppColor.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xs)
    }

    private var formattedProgress: String {
        book.progress.formatted(.percent.precision(.fractionLength(0)))
    }
}

#if DEBUG
struct InProgressRowView_Previews: PreviewProvider {
    static var previews: some View {
        InProgressRowView(book: .previewReading)
            .padding(Spacing.md)
            .background(AppColor.background)
    }
}
#endif
