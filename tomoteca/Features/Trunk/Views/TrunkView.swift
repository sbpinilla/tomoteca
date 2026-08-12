//
//  TrunkView.swift
//  tomoteca
//

import SwiftUI

/// The full book registry. Search, filters, adding and detail arrive in later milestones.
struct TrunkView: View {

    @StateObject private var viewModel: BookListViewModel

    init(repository: BookRepository) {
        _viewModel = StateObject(wrappedValue: BookListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            content
                .background(AppColor.background)
                .navigationTitle(Text(.tabTrunk))
        }
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
