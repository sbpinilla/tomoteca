//
//  TMProgressBar.swift
//  tomoteca
//

import SwiftUI

/// How far along something is, as a filled capsule over a recessed track.
///
/// Purely decorative: the figure it represents is always spelled out in words next to it, so
/// the bar is hidden from VoiceOver rather than read out as a second, vaguer version.
struct TMProgressBar: View {

    /// From 0 to 1. Clamped, so a value out of range shortens or fills the bar instead of
    /// drawing past its own edge.
    let value: Double
    var color: Color = AppColor.brandAccent

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.track)

                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: Spacing.sm)
        .accessibilityHidden(true)
    }
}

#if DEBUG
struct TMProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            TMProgressBar(value: 0)
            TMProgressBar(value: 0.62)
            TMProgressBar(value: 1)
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
