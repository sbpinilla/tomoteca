//
//  BookFormView.swift
//  tomoteca
//

import SwiftUI

/// The book form, presented as a sheet. Serves both adding a book from the trunk and editing
/// one from its detail; the mode decides the title, whether the status is offered, and whether
/// saving creates or overwrites.
struct BookFormView: View {

    @StateObject private var viewModel: BookFormViewModel
    @State private var isChoosingCover = false
    @Environment(\.dismiss) private var dismiss

    init(mode: BookFormMode, repository: BookRepository) {
        _viewModel = StateObject(
            wrappedValue: BookFormViewModel(mode: mode, repository: repository)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    coverButton
                }
                .listRowBackground(Color.clear)

                Section {
                    TMTextField(
                        label: .bookFormFieldTitle,
                        text: $viewModel.title,
                        isRequired: true
                    )

                    TMTextField(label: .bookFormFieldAuthor, text: $viewModel.author)

                    genrePicker

                    TMTextField(
                        label: .bookFormFieldPages,
                        text: $viewModel.pageCountText,
                        isRequired: true,
                        keyboardType: .numberPad
                    )
                }
                .listRowBackground(AppColor.surface)

                if viewModel.showsStatusPicker {
                    Section {
                        TMSegmentedPicker(
                            options: BookStatus.allCases,
                            title: \.shortTitle,
                            selection: $viewModel.status
                        )
                        .listRowInsets(EdgeInsets())
                    } header: {
                        TMText(
                            .bookFormInitialStatus,
                            style: .footnote,
                            color: AppColor.textSecondary
                        )
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .coverPicker(
                isPresented: $isChoosingCover,
                hasCover: viewModel.coverImageData != nil,
                onPick: { viewModel.coverImageData = $0 },
                onRemove: { viewModel.coverImageData = nil }
            )
            .navigationTitle(Text(viewModel.navigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(.bookFormCancel) }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if viewModel.save() { dismiss() }
                    } label: {
                        Text(.bookFormSave)
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    /// Offered here as a shortcut, not as the only chance: the cover can also be added later
    /// from the detail screen, which is when most people actually have the book in hand.
    private var coverButton: some View {
        Button {
            isChoosingCover = true
        } label: {
            HStack(spacing: Spacing.md) {
                TMBookCover(data: viewModel.coverImageData, width: 60, height: 84)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    TMText(
                        viewModel.coverImageData == nil ? .coverAdd : .coverChange,
                        style: .body,
                        color: AppColor.brandAccent
                    )
                    TMText(.coverAddHint, style: .footnote, color: AppColor.textSecondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("coverButton")
    }

    private var genrePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                TMText(.bookFormFieldGenre, style: .footnote, color: AppColor.textSecondary)
                TMText(verbatim: "*", style: .footnote, color: AppColor.brandAccent)
            }

            Picker(selection: $viewModel.genre) {
                Text(.bookFormGenrePlaceholder).tag(Genre?.none)

                ForEach(Genre.Section.allCases) { section in
                    Section {
                        ForEach(section.genres) { genre in
                            Text(genre.title).tag(Genre?.some(genre))
                        }
                    } header: {
                        Text(section.title)
                    }
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.navigationLink)
            .labelsHidden()
        }
        .padding(.vertical, Spacing.xs)
    }
}

#if DEBUG
struct BookFormView_Previews: PreviewProvider {
    static var previews: some View {
        BookFormView(mode: .add, repository: PreviewBookRepository.empty)
            .previewDisplayName("Alta")

        BookFormView(mode: .edit(.previewReading), repository: PreviewBookRepository.populated)
            .previewDisplayName("Edición")
    }
}
#endif
