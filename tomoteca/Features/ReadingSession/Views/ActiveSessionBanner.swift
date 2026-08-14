//
//  ActiveSessionBanner.swift
//  tomoteca
//

import Combine
import SwiftUI

/// Sits above the tab bar while a session is in progress, and reopens it when tapped.
///
/// Deliberately not a screen that takes over on launch: opening the app to look something up
/// should not be hijacked by a timer. But it stays visible, which is what was missing — an
/// interrupted session used to leave no trace at all.
struct ActiveSessionBanner: View {

    let bookTitle: String
    let remaining: TimeInterval
    let isExpired: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(AppColor.brandAccent)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 0) {
                    TMText(
                        isExpired ? .sessionBannerFinished : .sessionBannerResume,
                        style: .footnote,
                        color: AppColor.textPrimary
                    )
                    TMText(verbatim: bookTitle, style: .caption, color: AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: Spacing.sm)

                if !isExpired {
                    TMText(verbatim: formattedRemaining, style: .footnote, color: AppColor.brandAccent)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(AppColor.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(AppColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColor.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("activeSessionBanner")
    }

    private var formattedRemaining: String {
        let total = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#if DEBUG
struct ActiveSessionBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            ActiveSessionBanner(
                bookTitle: "Cien años de soledad",
                remaining: 452,
                isExpired: false
            ) {}

            ActiveSessionBanner(
                bookTitle: "Cien años de soledad",
                remaining: 0,
                isExpired: true
            ) {}
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif

extension View {

    /// Floats the session banner above this screen's content.
    ///
    /// Applied to each tab's content rather than to the `TabView` itself: an inset on the
    /// TabView lands across the tab bar, covering it. Inside a tab, the banner stops where the
    /// tab bar begins — above it, not on it.
    func activeSessionBanner(_ controller: ActiveSessionController) -> some View {
        safeAreaInset(edge: .bottom) {
            LiveSessionBanner(controller: controller)
        }
    }
}

/// Keeps the banner's countdown moving, and nothing else with it.
///
/// The tick lives here rather than at the root on purpose. Refreshing the banner by invalidating
/// the whole app once a second repainted the four tabs — and, worse, rebuilt the running
/// session's screen, whose own one-second timer was restarted before it could ever fire.
private struct LiveSessionBanner: View {

    @ObservedObject var controller: ActiveSessionController

    /// In `@State` so the subscription survives an update of this view: rebuilt each time, the
    /// timer would restart its one-second window instead of firing.
    @State private var tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    /// Changed on every tick for the sole purpose of redrawing. The time shown is still read
    /// from the clock below, so it can never be a stale copy.
    @State private var redraws = 0

    var body: some View {
        Group {
            if let book = controller.book {
                ActiveSessionBanner(
                    bookTitle: book.title,
                    remaining: controller.remaining,
                    isExpired: controller.isExpired
                ) {
                    controller.prepareViewModelIfNeeded()
                    controller.isPresenting = true
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
        .onReceive(tick) { _ in
            guard controller.hasActiveSession else { return }
            redraws &+= 1
        }
    }
}
