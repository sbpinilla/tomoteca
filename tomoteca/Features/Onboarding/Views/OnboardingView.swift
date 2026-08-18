//
//  OnboardingView.swift
//  tomoteca
//

import SwiftUI

/// Three swipeable screens introducing the app, shown once before the reader ever sees the
/// trunk. Skipping and finishing do the same thing: mark it seen, and hand off to `onFinished`.
struct OnboardingView: View {

    private struct Page {
        let systemImage: String
        let title: LocalizedStringResource
        let message: LocalizedStringResource
    }

    /// One icon per page, and each is the same one its feature already wears on the tab bar —
    /// onboarding borrows the app's own visual language instead of inventing one.
    private static let pages = [
        Page(systemImage: "archivebox", title: .onboardingPage1Title, message: .onboardingPage1Message),
        Page(systemImage: "book", title: .onboardingPage2Title, message: .onboardingPage2Message),
        Page(systemImage: "chart.bar", title: .onboardingPage3Title, message: .onboardingPage3Message),
    ]

    let onFinished: () -> Void

    @State private var page = 0

    private var isOnLastPage: Bool { page == Self.pages.count - 1 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $page) {
                ForEach(Array(Self.pages.enumerated()), id: \.offset) { index, item in
                    TMEmptyState(
                        systemImage: item.systemImage,
                        title: item.title,
                        message: item.message,
                        style: .hero
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            // Outside the paged content, so the page dots — which the system pins to the bottom
            // of the TabView itself — sit above it rather than underneath it. Only mounted at
            // all on the last page: an always-present button merely hidden via `.opacity` and
            // `.accessibilityHidden` still turned up in the accessibility tree on every page, so
            // "not offered yet" has to mean genuinely absent, not just invisible.
            .safeAreaInset(edge: .bottom) {
                if isOnLastPage {
                    TMButton(title: .onboardingGetStarted) { onFinished() }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                }
            }

            Button { onFinished() } label: { Text(.onboardingSkip) }
                .foregroundColor(AppColor.textSecondary)
                .padding(Spacing.md)
                .accessibilityIdentifier("onboardingSkip")
        }
        .background(AppColor.background)
        .onAppear {
            // The page dots default to the system's own colors; matched to the app's tokens the
            // same way `AppAppearance` already reaches into UIKit for the navigation bar.
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppColor.brandAccent)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppColor.track)
        }
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onFinished: {})
    }
}
#endif
