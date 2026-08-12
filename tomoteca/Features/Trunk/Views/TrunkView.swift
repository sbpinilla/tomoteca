//
//  TrunkView.swift
//  tomoteca
//

import SwiftUI

/// The full book registry. Search, filters, adding and detail arrive in later milestones.
struct TrunkView: View {

    @StateObject private var viewModel: BookListViewModel
    @State private var isAddingBook = Self.opensAddingBook

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
        _viewModel = StateObject(wrappedValue: BookListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            content
                .background(AppColor.background)
                .navigationTitle(Text(.tabTrunk))
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
                    BookFormView(repository: repository)
                }
        }
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
            VStack {
                Spacer()
                TMEmptyState(
                    systemImage: "books.vertical",
                    title: .trunkEmptyTitle,
                    message: .trunkEmptyMessage
                )
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.books) { book in
                BookRowView(book: book)
                    .listRowBackground(AppColor.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
}

#if DEBUG
struct TrunkView_Previews: PreviewProvider {
    static var previews: some View {
        TrunkView(repository: PreviewBookRepository.populated)
            .previewDisplayName("Con libros")

        TrunkView(repository: PreviewBookRepository.empty)
            .previewDisplayName("Vacío")
    }
}
#endif
