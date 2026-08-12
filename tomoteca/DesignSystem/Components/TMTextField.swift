//
//  TMTextField.swift
//  tomoteca
//

import SwiftUI

/// A form row: the label above, the value below.
///
/// Required fields carry an asterisk next to the label, so what is missing is visible before
/// the reader reaches a disabled save button.
struct TMTextField: View {

    let label: LocalizedStringResource
    @Binding var text: String
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                TMText(label, style: .footnote, color: AppColor.textSecondary)

                if isRequired {
                    TMText(verbatim: "*", style: .footnote, color: AppColor.brandAccent)
                }
            }

            // The visible label sits above the field, so the control itself has none. Without
            // this, VoiceOver would announce an unnamed text field.
            TextField("", text: $text)
                .font(AppFont.body)
                .foregroundColor(AppColor.textPrimary)
                .keyboardType(keyboardType)
                .accessibilityLabel(Text(label))
        }
        .padding(.vertical, Spacing.xs)
    }
}

#if DEBUG
struct TMTextField_Previews: PreviewProvider {
    @State private static var title = "Cien años de soledad"
    @State private static var author = ""

    static var previews: some View {
        VStack(spacing: Spacing.md) {
            TMTextField(label: .bookFormFieldTitle, text: $title, isRequired: true)
            TMTextField(label: .bookFormFieldAuthor, text: $author)
        }
        .padding(Spacing.md)
        .background(AppColor.surface)
    }
}
#endif
