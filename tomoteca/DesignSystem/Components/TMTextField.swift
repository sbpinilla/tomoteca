//
//  TMTextField.swift
//  tomoteca
//

import SwiftUI

/// A form row: the label above, the value below.
///
/// Required fields carry an asterisk next to the label, so what is missing is visible before
/// the reader reaches a disabled save button.
///
/// **The whole row takes the tap, not just the text.** A `TextField` only accepts touches on its
/// own line — around 20 points tall here — which means aiming at a single row of text. Everything
/// else in the row, including the empty space beside the value, now focuses the field too.
struct TMTextField: View {

    /// Apple's floor for anything meant to be tapped. Not a spacing choice, so it does not
    /// belong in the spacing scale: it is a platform constraint the row has to clear.
    private static let minimumTouchTarget: CGFloat = 44

    let label: LocalizedStringResource
    @Binding var text: String
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

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
                .focused($isFocused)
                .accessibilityLabel(Text(label))
        }
        .padding(.vertical, Spacing.sm)
        // A minimum rather than a fixed height: the row still grows with the text size instead
        // of clipping it.
        .frame(minHeight: Self.minimumTouchTarget, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Makes the gaps tappable too — without it, only the pixels with something drawn on
        // them would count.
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
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
