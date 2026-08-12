//
//  FinalPageSheet.swift
//  tomoteca
//

import SwiftUI

/// Asks where the reader got to. Cannot be dismissed: skipping it would throw away the time
/// that was just read.
struct FinalPageSheet: View {

    @ObservedObject var viewModel: ReadingSessionViewModel
    let onSaved: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                TMText(.finalPageTitle, style: .title)
                TMText(verbatim: viewModel.book.title, style: .footnote, color: AppColor.textSecondary)
            }
            .multilineTextAlignment(.center)

            TextField("", text: $viewModel.finalPageText)
                .font(AppFont.largeTitle)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding(Spacing.md)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(AppColor.brandAccent, lineWidth: 1)
                )
                .accessibilityLabel(Text(.finalPageTitle))
                .accessibilityIdentifier("finalPageField")

            if viewModel.showsPageOutOfRange {
                TMText(
                    .finalPageOutOfRange(viewModel.book.pageCount),
                    style: .footnote,
                    color: AppColor.brandAccent
                )
            } else {
                TMText(.finalPageHint, style: .footnote, color: AppColor.textSecondary)
            }

            TMButton(title: .finalPageSave) {
                if viewModel.save() { onSaved() }
            }
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1 : 0.5)

            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColor.background)
        .interactiveDismissDisabled()
    }
}
