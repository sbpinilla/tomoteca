//
//  BookFormView.swift
//  tomoteca
//

import SwiftUI

/// The add-book form, presented as a sheet from the trunk.
///
/// The cover picker arrives in Hito 4; showing a dead control here would promise something the
/// screen cannot do yet.
struct BookFormView: View {

    @StateObject private var viewModel: BookFormViewModel
    @Environment(\.dismiss) private var dismiss

    init(repository: BookRepository) {
        _viewModel = StateObject(wrappedValue: BookFormViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    TMSegmentedPicker(
                        options: BookStatus.allCases,
                        title: \.shortTitle,
                        selection: $viewModel.status
                    )
                    .listRowInsets(EdgeInsets())
                } header: {
                    TMText(.bookFormInitialStatus, style: .footnote, color: AppColor.textSecondary)
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle(Text(.bookFormNewTitle))
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
        BookFormView(repository: PreviewBookRepository.empty)
            .preferredColorScheme(.light)
            .previewDisplayName("Light")

        BookFormView(repository: PreviewBookRepository.empty)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
    }
}
#endif
