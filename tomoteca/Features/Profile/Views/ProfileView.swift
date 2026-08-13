//
//  ProfileView.swift
//  tomoteca
//

import SwiftUI

/// The fourth tab: things that act on the library as a whole rather than on one book.
///
/// A list with a single row today. It is called Profile, and it is a list, because signing in
/// is what comes next — renaming a tab once people know where it lives is worse than naming it
/// for what it is going to be.
struct ProfileView: View {

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    BookArchiveView(repository: repository)
                } label: {
                    TMText(.profileBooksRow, style: .body)
                }
                .listRowBackground(AppColor.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle(Text(.tabProfile))
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(repository: PreviewBookRepository.populated)
    }
}
#endif
