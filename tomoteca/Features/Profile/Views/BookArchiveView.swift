//
//  BookArchiveView.swift
//  tomoteca
//

import SwiftUI
import UniformTypeIdentifiers

/// Takes the library out to a file, and brings books back in from one.
struct BookArchiveView: View {

    @StateObject private var viewModel: BookArchiveViewModel
    @State private var isChoosingFile = false

    init(repository: BookRepository) {
        _viewModel = StateObject(wrappedValue: BookArchiveViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                exportSection

                Divider().background(AppColor.borderSubtle)

                importSection

                if let message = viewModel.errorMessage {
                    TMText(message, style: .footnote, color: AppColor.brandAccent)
                }
            }
            .padding(Spacing.md)
        }
        .background(AppColor.background)
        .navigationTitle(Text(.archiveTitle))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.exportedFile) { file in
            ShareSheet(items: [file.url])
        }
        .fileImporter(
            isPresented: $isChoosingFile,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                viewModel.import(from: url)
            case .failure:
                viewModel.importFailed()
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TMText(.archiveExportTitle, style: .title)

            // Said here, where the decision is made, rather than in small print somewhere else.
            TMText(
                .archiveExportMessage(viewModel.bookCount),
                style: .footnote,
                color: AppColor.textSecondary
            )

            TMButton(title: .archiveExportButton) { viewModel.export() }
                .padding(.top, Spacing.xs)
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TMText(.archiveImportTitle, style: .title)

            TMText(.archiveImportMessage, style: .footnote, color: AppColor.textSecondary)

            TMButton(title: .archiveImportButton, style: .secondary) { isChoosingFile = true }
                .padding(.top, Spacing.xs)

            if let result = viewModel.lastImport {
                summary(for: result)
            }
        }
    }

    /// How many went in, how many stayed out, and why. The reason is the part that matters: with
    /// only a count, a hand-written file gets corrected by guesswork.
    private func summary(for result: BookArchive.ImportResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            TMText(
                result.skippedCount == 0
                    ? .archiveSummaryNoneSkipped(result.importedCount)
                    : .archiveSummary(result.importedCount, result.skippedCount),
                style: .body,
                color: AppColor.brandPrimary
            )

            ForEach(BookArchive.SkipReason.allCases, id: \.self) { reason in
                if let count = result.skipped[reason], count > 0 {
                    TMText(
                        .archiveSkippedLine(count, String(localized: reason.title)),
                        style: .footnote,
                        color: AppColor.textSecondary
                    )
                }
            }
        }
        .padding(.top, Spacing.sm)
    }
}

extension BookArchive.SkipReason {

    var title: LocalizedStringResource {
        switch self {
        case .missingFields: return .archiveSkipMissingFields
        case .unknownGenre: return .archiveSkipUnknownGenre
        case .unknownStatus: return .archiveSkipUnknownStatus
        case .invalidNumbers: return .archiveSkipInvalidNumbers
        case .alreadyPresent: return .archiveSkipAlreadyPresent
        }
    }
}

#if DEBUG
struct BookArchiveView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookArchiveView(repository: PreviewBookRepository.populated)
        }
    }
}
#endif
