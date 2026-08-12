//
//  TokensGallery.swift
//  tomoteca
//

#if DEBUG
import SwiftUI

/// Preview-only catalog of every design token, in light and dark.
///
/// This is the reference to check before writing any UI: if a color or a text role
/// is not here, it does not exist. Debug-only, never shipped and never navigated to.
struct TokensGallery: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                section("Surfaces") {
                    swatch("background", AppColor.background)
                    swatch("surface", AppColor.surface)
                    swatch("borderSubtle", AppColor.borderSubtle)
                }

                section("Content") {
                    swatch("textPrimary", AppColor.textPrimary)
                    swatch("textSecondary", AppColor.textSecondary)
                }

                section("Brand") {
                    swatch("brandPrimary", AppColor.brandPrimary)
                    swatch("brandAccent", AppColor.brandAccent)
                }

                section("Status") {
                    statusRow("wishlist", AppColor.Status.wishlist)
                    statusRow("owned", AppColor.Status.owned)
                    statusRow("reading", AppColor.Status.reading)
                    statusRow("finished", AppColor.Status.finished)
                }

                section("Typography") {
                    Text("largeTitle").font(AppFont.largeTitle)
                    Text("title").font(AppFont.title)
                    Text("headline").font(AppFont.headline)
                    Text("body").font(AppFont.body)
                    Text("callout").font(AppFont.callout)
                    Text("caption").font(AppFont.caption)
                }
                .foregroundColor(AppColor.textPrimary)
            }
            .padding(Spacing.md)
        }
        .background(AppColor.background)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
            content()
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                )
            Text(name)
                .font(AppFont.body)
                .foregroundColor(AppColor.textPrimary)
        }
    }

    /// Renders a status pair exactly as a chip would use it.
    private func statusRow(_ name: String, _ palette: StatusPalette) -> some View {
        HStack(spacing: Spacing.md) {
            Text(name)
                .font(AppFont.caption)
                .foregroundColor(palette.foreground)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(palette.background)
                .clipShape(Capsule())
            Spacer()
        }
    }
}

struct TokensGallery_Previews: PreviewProvider {
    static var previews: some View {
        TokensGallery()
            .preferredColorScheme(.light)
            .previewDisplayName("Light")

        TokensGallery()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
    }
}
#endif
