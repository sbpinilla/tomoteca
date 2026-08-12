//
//  TrackingView.swift
//  tomoteca
//

import Charts
import SwiftUI

/// Reading time per day over a recent stretch.
struct TrackingView: View {

    @StateObject private var viewModel: TrackingViewModel

    init(repository: ReadingSessionRepository) {
        _viewModel = StateObject(wrappedValue: TrackingViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    TMSegmentedPicker(
                        options: TrackingViewModel.Range.allCases,
                        title: { LocalizedStringResource.trackingRangeDays($0.days) },
                        selection: $viewModel.range
                    )

                    HStack(spacing: Spacing.md) {
                        TMStatTile(
                            label: .trackingTotal,
                            value: .trackingMinutes(viewModel.totalMinutes)
                        )
                        TMStatTile(
                            label: .trackingAverage,
                            value: .trackingMinutes(viewModel.averageMinutesPerDay)
                        )
                    }

                    if viewModel.hasNoSessions {
                        TMEmptyState(
                            systemImage: "chart.bar",
                            title: .trackingEmptyTitle,
                            message: .trackingEmptyMessage
                        )
                        .padding(.top, Spacing.xl)
                    } else {
                        chart
                    }
                }
                .padding(Spacing.md)
            }
            .background(AppColor.background)
            .navigationTitle(Text(.tabTracking))
        }
    }

    private var chart: some View {
        Chart(viewModel.dailyTotals) { total in
            BarMark(
                x: .value("day", total.day, unit: .day),
                y: .value("minutes", total.minutes)
            )
            .foregroundStyle(
                viewModel.isToday(total)
                    ? AppColor.brandAccent
                    // A faded accent rather than `track`: on the dark surface those two sit
                    // within a hair of each other and the bars vanish into the card.
                    : AppColor.brandAccent.opacity(Self.mutedBarOpacity)
            )
            .cornerRadius(Radius.sm)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            // One label per day on a week, thinned out on longer ranges so they stay readable.
            AxisMarks(values: .stride(by: .day, count: strideDays)) { value in
                AxisValueLabel(format: axisFormat)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(height: 220)
        .padding(Spacing.md)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .accessibilityLabel(Text(.trackingChartLabel))
    }

    /// Enough to read the shape of the week, faint enough that today still stands out.
    private static let mutedBarOpacity = 0.35

    private var strideDays: Int {
        switch viewModel.range {
        case .week: return 1
        case .fortnight: return 3
        case .month: return 7
        }
    }

    /// Weekday initials on a week, day-and-month once the range is long enough that a weekday
    /// stops telling you which day it was.
    private var axisFormat: Date.FormatStyle {
        viewModel.range == .week
            ? .dateTime.weekday(.narrow)
            : .dateTime.day().month(.narrow)
    }
}

#if DEBUG
struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView(repository: PreviewReadingSessionRepository(sessions: .previewWeek))
            .previewDisplayName("Con sesiones")

        TrackingView(repository: PreviewReadingSessionRepository())
            .previewDisplayName("Vacío")
    }
}
#endif
