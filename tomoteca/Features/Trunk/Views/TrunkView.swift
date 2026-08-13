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
                    BookFormView(mode: .add, repository: repository)
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
        .searchable(
            text: $viewModel.searchText,
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
                filterMenu

                if viewModel.hasNoResults {
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

    /// Five options counting "All" — too many for a segmented control, so a menu it is.
    private var filterMenu: some View {
        HStack {
            Menu {
                Picker(selection: $viewModel.filter) {
                    ForEach(BookListViewModel.Filter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    TMText(viewModel.filter.title, style: .body)
                    Image(systemName: "chevron.down")
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(AppColor.surface)
                .clipShape(Capsule())
            }
            .accessibilityLabel(Text(.trunkFilterLabel))
            .accessibilityIdentifier("statusFilter")

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
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
