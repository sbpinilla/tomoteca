//
//  TMSegmentedPicker.swift
//  tomoteca
//

import SwiftUI

/// A segmented control drawn with the app's own tokens.
///
/// The system's segmented picker cannot take the recessed `track` color the design calls for,
/// so this one is built from a capsule and a moving thumb.
///
/// Generic over the value and takes a title for each option, so it stays free of any domain
/// knowledge: statuses today, date ranges in the tracking tab later.
struct TMSegmentedPicker<Value: Hashable>: View {

    let options: [Value]
    let title: (Value) -> LocalizedStringResource
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    TMText(
                        title(option),
                        style: .footnote,
                        color: option == selection ? AppColor.textPrimary : AppColor.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(thumb(isSelected: option == selection))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? [.isSelected] : [])
            }
        }
        .padding(Spacing.xs)
        .background(AppColor.track)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func thumb(isSelected: Bool) -> some View {
        if isSelected {
            Capsule().fill(AppColor.surface)
        } else {
            Color.clear
        }
    }
}

#if DEBUG
struct TMSegmentedPicker_Previews: PreviewProvider {
    @State private static var status: BookStatus = .wishlist

    static var previews: some View {
        TMSegmentedPicker(
            options: BookStatus.allCases,
            title: \.shortTitle,
            selection: $status
        )
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
