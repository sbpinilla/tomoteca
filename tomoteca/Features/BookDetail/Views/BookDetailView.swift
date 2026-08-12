//
//  BookDetailView.swift
//  tomoteca
//

import SwiftUI

/// The book's file card, reached from any of the three tabs.
///
/// Editing arrives in Hito 5 and the reading session in Hito 6; neither is drawn until it works.
struct BookDetailView: View {

    @StateObject private var viewModel: BookDetailViewModel
    @State private var isChoosingCover = false
    @State private var isEditing = false

    private let repository: BookRepository

    init(book: Book, repository: BookRepository) {
        self.repository = repository
        _viewModel = StateObject(
            wrappedValue: BookDetailViewModel(book: book, repository: repository)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                cover

                VStack(spacing: Spacing.xs) {
                    TMText(verbatim: viewModel.book.title, style: .title)
                        .multilineTextAlignment(.center)

                    TMText(verbatim: subtitle, style: .footnote, color: AppColor.textSecondary)

                    TMStatusChip(
                        title: viewModel.book.status.title,
                        color: viewModel.book.status.color
                    )
                    .padding(.top, Spacing.xs)
                }

                progress

                statusRow
            }
            .padding(Spacing.md)
        }
        .background(AppColor.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isEditing = true } label: { Text(.bookDetailEdit) }
            }
        }
        .sheet(isPresented: $isEditing) {
            BookFormView(mode: .edit(viewModel.book), repository: repository)
        }
        .coverPicker(
            isPresented: $isChoosingCover,
            hasCover: viewModel.book.coverImageData != nil,
            onPick: viewModel.setCover,
            onRemove: viewModel.removeCover
        )
        .sheet(isPresented: $viewModel.isChangingStatus) {
            StatusChangeSheet(
                book: viewModel.book,
                nextStatus: viewModel.nextStatus,
                onAdvance: viewModel.advanceStatus
            )
            .presentationDetents([.height(360)])
        }
    }

    /// Tapping the cover is the main way to add one: most books are registered before their
    /// photo is at hand, and this saves a trip through the edit form later.
    private var cover: some View {
        Button {
            isChoosingCover = true
        } label: {
            TMBookCover(
                data: viewModel.book.coverImageData,
                width: 160,
                height: 230,
                cornerRadius: Radius.lg
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(viewModel.book.coverImageData == nil ? .coverAdd : .coverChange))
        .accessibilityIdentifier("coverButton")
    }

    private var progress: some View {
        VStack(spacing: Spacing.sm) {
            TMProgressBar(value: viewModel.book.progress, color: viewModel.book.status.color)

            HStack(spacing: Spacing.xs) {
                TMText(
                    .bookDetailPageProgress(viewModel.book.currentPage, viewModel.book.pageCount),
                    style: .footnote,
                    color: AppColor.textSecondary
                )
                TMText(verbatim: "·", style: .footnote, color: AppColor.textSecondary)
                TMText(verbatim: formattedProgress, style: .footnote, color: AppColor.textSecondary)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private var statusRow: some View {
        Button {
            viewModel.isChangingStatus = true
        } label: {
            HStack {
                TMText(.bookDetailStatusRow, style: .body, color: AppColor.textSecondary)
                Spacer()
                TMText(viewModel.book.status.title, style: .body)
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColor.textSecondary)
            }
            .padding(Spacing.md)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        // VoiceOver reads the row as "Status, Bought", which is right for a reader but not
        // something a test can match on. The identifier stays put as the label changes.
        .accessibilityIdentifier("statusRow")
    }

    private var subtitle: String {
        let genre = String(localized: viewModel.book.genre.title)
        guard let author = viewModel.book.author, !author.isEmpty else { return genre }
        return "\(author) · \(genre)"
    }

    private var formattedProgress: String {
        viewModel.book.progress.formatted(.percent.precision(.fractionLength(0)))
    }
}

#if DEBUG
struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookDetailView(book: .previewReading, repository: PreviewBookRepository.populated)
        }
        .previewDisplayName("Light")

        NavigationStack {
            BookDetailView(book: .previewFinished, repository: PreviewBookRepository.populated)
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark")
    }
}
#endif
