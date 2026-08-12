//
//  StatusChangeSheet.swift
//  tomoteca
//

import SwiftUI

/// Advances a book one step along its life cycle.
///
/// Offers exactly one action: the next status. A finished book gets no button at all, only the
/// completed stepper and the note explaining why there is nothing to press.
struct StatusChangeSheet: View {

    let book: Book
    let nextStatus: BookStatus?
    let onAdvance: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                TMText(.statusChangeTitle, style: .title)
                TMText(verbatim: book.title, style: .footnote, color: AppColor.textSecondary)
            }

            StatusStepperView(current: book.status)

            HStack(spacing: Spacing.sm) {
                TMText(.statusChangeCurrent, style: .body, color: AppColor.textSecondary)
                TMText(book.status.title, style: .body, color: book.status.color)
            }

            if let nextStatus {
                TMButton(title: action(for: nextStatus), action: onAdvance)
            }

            TMText(.statusChangeFootnote, style: .footnote, color: AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
    }

    /// Names the destination rather than the act: "Mark as finished" reads as what will happen,
    /// where a generic "Change" would not.
    private func action(for status: BookStatus) -> LocalizedStringResource {
        switch status {
        case .owned: return .statusChangeActionOwned
        case .reading: return .statusChangeActionReading
        case .finished: return .statusChangeActionFinished
        case .wishlist: return .statusChangeActionOwned  // unreachable: nothing advances into it
        }
    }
}

#if DEBUG
struct StatusChangeSheet_Previews: PreviewProvider {
    static var previews: some View {
        StatusChangeSheet(book: .previewReading, nextStatus: .finished) {}
            .previewDisplayName("Leyendo")

        StatusChangeSheet(book: .previewFinished, nextStatus: nil) {}
            .previewDisplayName("Sin avance posible")
    }
}
#endif
