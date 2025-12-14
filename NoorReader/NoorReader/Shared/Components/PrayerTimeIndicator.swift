// PrayerTimeIndicator.swift
// NoorReader
//
// Prayer time widget for toolbar

import SwiftUI

struct PrayerTimeIndicator: View {
    @State private var service = PrayerTimeService.shared

    var body: some View {
        Group {
            if service.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else if let prayer = service.nextPrayer {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars")
                        .font(.caption)
                        .foregroundStyle(Color.noorGold)

                    Text("\(prayer.rawValue)")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text(service.timeUntilNextPrayer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .help("Next prayer: \(prayer.rawValue) in \(service.timeUntilNextPrayer)")
            } else {
                Image(systemName: "moon.stars")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            service.startUpdating()
        }
        .onDisappear {
            service.stopUpdating()
        }
    }
}

// Expanded view for settings or popover
struct PrayerTimesView: View {
    @State private var service = PrayerTimeService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(Color.noorGold)
                Text("Prayer Times")
                    .font(.headline)
                Spacer()

                Button(action: {
                    Task { await service.refresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            Divider()

            if let times = service.prayerTimes {
                prayerRow(.fajr, time: times.fajr)
                prayerRow(.dhuhr, time: times.dhuhr)
                prayerRow(.asr, time: times.asr)
                prayerRow(.maghrib, time: times.maghrib)
                prayerRow(.isha, time: times.isha)
            } else if service.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Unable to load prayer times")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 200)
    }

    @ViewBuilder
    private func prayerRow(_ prayer: Prayer, time: Date?) -> some View {
        HStack {
            Image(systemName: prayer.icon)
                .frame(width: 20)
                .foregroundStyle(service.nextPrayer == prayer ? Color.noorGold : .secondary)

            Text(prayer.rawValue)
                .fontWeight(service.nextPrayer == prayer ? .semibold : .regular)

            Spacer()

            if let time {
                Text(time, style: .time)
                    .foregroundStyle(service.nextPrayer == prayer ? .primary : .secondary)
            } else {
                Text("--:--")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .background(service.nextPrayer == prayer ? Color.noorGold.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    PrayerTimesView()
}
