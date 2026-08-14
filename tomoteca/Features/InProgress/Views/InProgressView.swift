//
//  InProgressView.swift
//  tomoteca
//

import SwiftUI

/// Books currently being read, and the way into a reading session.
struct InProgressView: View {

    @StateObject private var viewModel: InProgressViewModel

    private let bookRepository: BookRepository
    private let notifications: any SessionNotificationScheduling
    private let sessionController: ActiveSessionController

    init(
        bookRepository: BookRepository,
        notifications: any SessionNotificationScheduling,
        sessionController: ActiveSessionController
    ) {
        self.bookRepository = bookRepository
        self.notifications = notifications
        self.sessionController = sessionController
        _viewModel = StateObject(wrappedValue: InProgressViewModel(repository: bookRepository))
    }

    var body: some View {
        NavigationStack {
            content
                .background(AppColor.background)
                .navigationTitle(Text(.tabInProgress))
                .navigationDestination(for: Book.self) { book in
                    BookDetailView(
                        book: book,
                        repository: bookRepository,
                        notifications: notifications,
                        sessionController: sessionController
                    )
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            VStack {
                Spacer()
                TMEmptyState(
                    systemImage: "book",
                    title: .inProgressEmptyTitle,
                    message: .inProgressEmptyMessage
                )
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.books) { book in
                    NavigationLink(value: book) {
                        InProgressRowView(book: book)
                    }
                    .listRowBackground(AppColor.surface)
                }

                // Reading is what this tab is for, and with a single book there is nothing to
                // pick: going into it to press a button is a step that decides nothing.
                if let book = viewModel.onlyBook {
                    SessionStartButton(
                        book: book,
                        sessionController: sessionController,
                        notifications: notifications
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: Spacing.md, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
}

#if DEBUG
struct InProgressView_Previews: PreviewProvider {
    static var previews: some View {
        InProgressView(
            bookRepository: PreviewBookRepository.populated,
            notifications: PreviewNotificationScheduler(),
            sessionController: .preview
        )
    }
}
#endif
