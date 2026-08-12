//
//  BookRowView.swift
//  tomoteca
//

import SwiftUI

/// One book in the trunk list: cover, title, author and genre, and its status.
struct BookRowView: View {

    let book: Book

    var body: some View {
        HStack(spacing: Spacing.md) {
            cover

            VStack(alignment: .leading, spacing: Spacing.xs) {
                TMText(verbatim: book.title, style: .headline)

                TMText(verbatim: subtitle, style: .footnote, color: AppColor.textSecondary)

                HStack(spacing: Spacing.xs) {
                    TMStatusChip(title: book.status.title, color: book.status.color)

                    // Progress only earns its place while the book is being read.
                    if book.status == .reading {
                        TMText(verbatim: "·", style: .footnote, color: book.status.color)
                        TMText(verbatim: formattedProgress, style: .footnote, color: book.status.color)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xs)
    }

    private var cover: some View {
        TMBookCover(data: book.coverImageData, width: 44, height: 62)
    }

    /// "Author · Genre", or just the genre when the author is unknown.
    private var subtitle: String {
        let genre = String(localized: book.genre.title)
        guard let author = book.author, !author.isEmpty else { return genre }
        return "\(author) · \(genre)"
    }

    private var formattedProgress: String {
        book.progress.formatted(.percent.precision(.fractionLength(0)))
    }
}

#if DEBUG
struct BookRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            BookRowView(book: .previewReading)
            BookRowView(book: .previewOwned)
            BookRowView(book: .previewWishlist)
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
