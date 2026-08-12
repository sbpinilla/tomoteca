//
//  TMBookCover.swift
//  tomoteca
//

import SwiftUI

/// A book cover, or the placeholder that stands in until there is one.
///
/// Takes raw image data rather than a book: the design system does not know what a book is.
struct TMBookCover: View {

    let data: Data?
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = Radius.sm

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        // Decorative: the title sits right next to it, so announcing the cover adds nothing.
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        AppColor.track
            .overlay(
                Image(systemName: "book.closed")
                    .foregroundColor(AppColor.textSecondary)
            )
    }
}

#if DEBUG
struct TMBookCover_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: Spacing.md) {
            TMBookCover(data: nil, width: 44, height: 62)
            TMBookCover(
                data: UIImage.sampleCover(color: .systemTeal).coverData(),
                width: 44,
                height: 62
            )
            TMBookCover(data: nil, width: 160, height: 230, cornerRadius: Radius.lg)
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
