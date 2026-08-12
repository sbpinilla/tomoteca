//
//  TMStatTile.swift
//  tomoteca
//

import SwiftUI

/// A single figure with its label: the tiles at the top of the tracking tab.
struct TMStatTile: View {

    let label: LocalizedStringResource
    let value: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            TMText(label, style: .footnote, color: AppColor.textSecondary)
            TMText(value, style: .title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(AppColor.borderSubtle, lineWidth: 1)
        )
        // Read as one phrase — "Total, 142 min" — rather than two loose fragments.
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct TMStatTile_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: Spacing.md) {
            TMStatTile(label: .trackingTotal, value: .trackingMinutes(142))
            TMStatTile(label: .trackingAverage, value: .trackingMinutes(20))
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
