//
//  TMProgressRing.swift
//  tomoteca
//

import SwiftUI

/// A circular progress track with something in the middle.
///
/// Decorative like the bar: whatever it represents is spelled out in the label inside it, so
/// VoiceOver reads that rather than a second, vaguer version of the same thing.
struct TMProgressRing<Content: View>: View {

    /// From 0 to 1, clamped.
    let value: Double
    var lineWidth: CGFloat = 12
    var color: Color = AppColor.brandAccent
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.track, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(1, max(0, value)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                // Starts at the top and runs clockwise, the way a clock face is read.
                .rotationEffect(.degrees(-90))

            content()
        }
    }
}

#if DEBUG
struct TMProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: Spacing.lg) {
            TMProgressRing(value: 0.25) {
                TMText(verbatim: "07:32", style: .title)
            }
            TMProgressRing(value: 1) {
                TMText(verbatim: "00:00", style: .title)
            }
        }
        .frame(height: 160)
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
