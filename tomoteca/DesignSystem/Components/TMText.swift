//
//  TMText.swift
//  tomoteca
//

import SwiftUI

/// Text with its typographic role and color already paired.
///
/// Views never set a font and a color separately: they pick a role, and the pairing lives here
/// once. The two initialisers draw the line that matters for localization — interface copy is
/// translated, and content the user typed is shown exactly as they typed it.
struct TMText: View {

    enum Style {
        case largeTitle
        case title
        case headline
        case body
        case callout
        case footnote
        case caption
    }

    private enum Content {
        case localized(LocalizedStringResource)
        case verbatim(String)
    }

    private let content: Content
    private let style: Style
    private let color: Color

    /// Interface copy, translated through the string catalog.
    init(_ resource: LocalizedStringResource, style: Style, color: Color = AppColor.textPrimary) {
        self.content = .localized(resource)
        self.style = style
        self.color = color
    }

    /// Content the user owns — a book title, an author. Never translated.
    init(verbatim string: String, style: Style, color: Color = AppColor.textPrimary) {
        self.content = .verbatim(string)
        self.style = style
        self.color = color
    }

    var body: some View {
        text
            .font(font)
            .foregroundColor(color)
    }

    private var text: Text {
        switch content {
        case .localized(let resource):
            return Text(resource)
        case .verbatim(let string):
            return Text(verbatim: string)
        }
    }

    private var font: Font {
        switch style {
        case .largeTitle: return AppFont.largeTitle
        case .title: return AppFont.title
        case .headline: return AppFont.headline
        case .body: return AppFont.body
        case .callout: return AppFont.callout
        case .footnote: return AppFont.footnote
        case .caption: return AppFont.caption
        }
    }
}

#if DEBUG
struct TMText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TMText(verbatim: "Cien años de soledad", style: .headline)
            TMText(verbatim: "García Márquez", style: .footnote, color: AppColor.textSecondary)
            TMText(.trunkEmptyTitle, style: .title)
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
