//
//  ReadingSessionLiveActivity.swift
//  tomotecaWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

/// The reading session on the Dynamic Island and the Lock Screen.
///
/// Deliberately plain — the Dynamic Island is tiny and already sits on the system's own black,
/// so this leans on system materials and SF Symbols rather than the app's own color tokens,
/// which live in the app target and are not worth pulling into a second one for a few lines of
/// text. `.rounded` keeps the family resemblance without needing the app's `AppFont`.
@available(iOS 16.2, *)
struct ReadingSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingSessionActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimeView(state: context.state)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.bookTitle)
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    StopLink()
                }
            } compactLeading: {
                Image(systemName: "book.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                TimeView(state: context.state)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .frame(width: 46)
            } minimal: {
                Image(systemName: "book.fill")
                    .foregroundStyle(.orange)
            }
            .widgetURL(SessionActivityLink.stop)
            .keylineTint(.orange)
        }
    }
}

/// Where a reader on the book's own Lock Screen widget sees the same thing the Dynamic Island
/// shows, plus room enough for the "Stop" link to carry a label.
@available(iOS 16.2, *)
private struct LockScreenView: View {
    let attributes: ReadingSessionActivityAttributes
    let state: ReadingSessionActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.bookTitle)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .lineLimit(1)
                TimeView(state: state)
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }

            Spacer(minLength: 8)

            StopLink()
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}

/// The number itself: a live countdown when there is a fixed end to count to, or a plain string
/// the app pushed the last time it changed — while paused, or for a free session, which never
/// has an end date to animate towards on its own.
@available(iOS 16.2, *)
private struct TimeView: View {
    let state: ReadingSessionActivityAttributes.ContentState

    var body: some View {
        if let endDate = state.endDate, !state.isPaused {
            Text(timerInterval: Date.now...endDate, countsDown: true)
                .monospacedDigit()
        } else {
            Text(state.frozenDisplay)
                .monospacedDigit()
        }
    }
}

@available(iOS 16.2, *)
private struct StopLink: View {
    var body: some View {
        Link(destination: SessionActivityLink.stop) {
            Label {
                Text(.widgetStop)
            } icon: {
                Image(systemName: "stop.fill")
            }
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.18), in: Capsule())
        }
    }
}
