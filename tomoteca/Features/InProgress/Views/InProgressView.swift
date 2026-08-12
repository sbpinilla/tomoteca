//
//  InProgressView.swift
//  tomoteca
//

import SwiftUI

/// Books currently being read, and the way into a reading session.
struct InProgressView: View {

    @StateObject private var viewModel: InProgressViewModel

    private let bookRepository: BookRepository
    private let sessionRepository: ReadingSessionRepository
    private let notifications: any SessionNotificationScheduling

    init(
        bookRepository: BookRepository,
        sessionRepository: ReadingSessionRepository,
        notifications: any SessionNotificationScheduling
    ) {
        self.bookRepository = bookRepository
        self.sessionRepository = sessionRepository
        self.notifications = notifications
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
                        sessionRepository: sessionRepository,
                        notifications: notifications
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
            List(viewModel.books) { book in
                NavigationLink(value: book) {
                    InProgressRowView(book: book)
                }
                .listRowBackground(AppColor.surface)
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
            sessionRepository: PreviewReadingSessionRepository(),
            notifications: PreviewNotificationScheduler()
        )
    }
}
#endif
