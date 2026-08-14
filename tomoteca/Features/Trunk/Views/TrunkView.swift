//
//  TrunkView.swift
//  tomoteca
//

import SwiftUI

/// The full book registry: search, filter, add, open and delete.
struct TrunkView: View {

    @StateObject private var viewModel: BookListViewModel
    @State private var isAddingBook = Self.opensAddingBook
    /// The book a swipe is asking to delete, if any. Holding the book rather than a flag keeps
    /// the alert naming the right one even as the list changes underneath.
    @State private var bookPendingDeletion: Book?

    private let repository: BookRepository
    private let notifications: any SessionNotificationScheduling
    private let sessionController: ActiveSessionController

    init(
        repository: BookRepository,
        notifications: any SessionNotificationScheduling,
        sessionController: ActiveSessionController
    ) {
        self.repository = repository
        self.notifications = notifications
        self.sessionController = sessionController
        _viewModel = StateObject(wrappedValue: BookListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            content
                .background(AppColor.background)
                .navigationTitle(Text(.tabTrunk))
                .navigationDestination(for: Book.self) { book in
                    BookDetailView(
                        book: book,
                        repository: repository,
                        notifications: notifications,
                        sessionController: sessionController
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isAddingBook = true
                        } label: {
                            Image(systemName: "plus")
                                .accessibilityLabel(Text(.trunkAddBook))
                        }
                    }
                }
                .sheet(isPresented: $isAddingBook) {
                    // Follows the new book to wherever it landed: saving something you then
                    // cannot see reads as a button that did nothing.
                    BookFormView(mode: .add, repository: repository) { saved in
                        viewModel.shelf = saved.status
                    }
                }
                .alert(item: $bookPendingDeletion) { book in
                    Alert(
                        title: Text(.deleteBookTitle(book.title)),
                        message: Text(.deleteBookMessage),
                        primaryButton: .destructive(Text(.commonDelete)) {
                            viewModel.delete(book)
                        },
                        secondaryButton: .cancel(Text(.commonCancel))
                    )
                }
        }
        // Attached outside the branch so the field does not disappear when a search empties the
        // list — which would leave no way to undo the search.
        //
        // Pinned with `.always` because the default drawer is allowed to collapse into the
        // navigation bar, and coming back from a book it never came out again: the field was
        // gone for good until the tab was left and re-entered.
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(.trunkSearchPrompt)
        )
    }

    /// Opens straight into the form when a debug run passes `-startAddingBook`, so the sheet can
    /// be captured without tapping through the app.
    private static var opensAddingBook: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "startAddingBook")
        #else
        return false
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            centered {
                TMEmptyState(
                    systemImage: "books.vertical",
                    title: .trunkEmptyTitle,
                    message: .trunkEmptyMessage
                )
            }
        } else {
            VStack(spacing: 0) {
                shelfChips

                if viewModel.isShelfEmpty {
                    centered {
                        TMEmptyState(
                            systemImage: "books.vertical",
                            title: .trunkEmptyStatusTitle,
                            message: .trunkEmptyStatusMessage
                        )
                    }
                } else if viewModel.hasNoResults {
                    centered {
                        TMEmptyState(
                            systemImage: "magnifyingglass",
                            title: .trunkNoResultsTitle,
                            message: .trunkNoResultsMessage
                        )
                    }
                } else {
                    list
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.visibleBooks) { book in
                NavigationLink(value: book) {
                    BookRowView(book: book)
                }
                .listRowBackground(AppColor.surface)
            }
            // Kept as `onDelete` rather than a hand-rolled swipe action, so the row keeps the
            // system's own delete affordance. It no longer deletes on the spot: it names the
            // book for the alert, and the row springs back if the answer is no.
            .onDelete { offsets in
                bookPendingDeletion = viewModel.book(atOffsets: offsets)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    /// One chip per shelf, always with one chosen. There is no "everything" — that is what made
    /// the list unreadable once the library grew.
    ///
    /// Scrolls sideways because four chips with their counts do not fit across a phone, and fit
    /// even less at accessibility text sizes.
    private var shelfChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.shelves) { status in
                    TMShelfChip(
                        title: status.shortTitle,
                        count: viewModel.count(of: status),
                        color: status.color,
                        isSelected: viewModel.shelf == status
                    ) {
                        viewModel.shelf = status
                    }
                    .accessibilityIdentifier("shelf-\(status.archiveName)")
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .accessibilityLabel(Text(.trunkStatusFilterLabel))
        .padding(.bottom, Spacing.sm)
    }

    private func centered<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            Spacer()
            content()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct TrunkView_Previews: PreviewProvider {
    static var previews: some View {
        TrunkView(
            repository: PreviewBookRepository.populated,
            notifications: PreviewNotificationScheduler(),
            sessionController: .preview
        )
        .previewDisplayName("Con libros")

        TrunkView(
            repository: PreviewBookRepository.empty,
            notifications: PreviewNotificationScheduler(),
            sessionController: .preview
        )
        .previewDisplayName("Vacío")
    }
}
#endif
