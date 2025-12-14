// PrayerTimeService.swift
// NoorReader
//
// Prayer time service using Aladhan API

import Foundation
import CoreLocation

@MainActor
@Observable
final class PrayerTimeService: NSObject {
    static let shared = PrayerTimeService()

    private(set) var prayerTimes: PrayerTimes?
    private(set) var nextPrayer: Prayer?
    private(set) var timeUntilNextPrayer: String = ""
    private(set) var isLoading = false
    private(set) var error: Error?

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var updateTimer: Timer?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Public Methods

    func startUpdating() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Update time remaining every minute
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.updateNextPrayer()
            }
        }
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func refresh() async {
        guard let location = currentLocation else { return }
        await fetchPrayerTimes(for: location)
    }

    // MARK: - Private Methods

    private func fetchPrayerTimes(for location: CLLocation) async {
        isLoading = true
        error = nil

        do {
            let times = try await fetchFromAladhan(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            self.prayerTimes = times
            self.updateNextPrayer()
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }

    private func fetchFromAladhan(latitude: Double, longitude: Double) async throws -> PrayerTimes {
        // Get calculation method from settings (default: ISNA)
        let method = UserDefaults.standard.integer(forKey: "prayerCalculationMethod")
        let methodParam = method > 0 ? method : 2 // ISNA = 2

        let urlString = "https://api.aladhan.com/v1/timings/\(Int(Date().timeIntervalSince1970))?latitude=\(latitude)&longitude=\(longitude)&method=\(methodParam)"

        guard let url = URL(string: urlString) else {
            throw PrayerTimeError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PrayerTimeError.serverError
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(AladhanResponse.self, from: data)

        return apiResponse.data.timings.toPrayerTimes()
    }

    private func updateNextPrayer() {
        guard let times = prayerTimes else { return }

        let now = Date()
        let calendar = Calendar.current

        let prayers: [(Prayer, Date?)] = [
            (.fajr, times.fajr),
            (.dhuhr, times.dhuhr),
            (.asr, times.asr),
            (.maghrib, times.maghrib),
            (.isha, times.isha)
        ]

        // Find next prayer
        for (prayer, time) in prayers {
            guard let prayerTime = time, prayerTime > now else { continue }

            nextPrayer = prayer

            // Calculate time remaining
            let components = calendar.dateComponents([.hour, .minute], from: now, to: prayerTime)
            if let hours = components.hour, let minutes = components.minute {
                if hours > 0 {
                    timeUntilNextPrayer = "\(hours)h \(minutes)m"
                } else {
                    timeUntilNextPrayer = "\(minutes)m"
                }
            }
            return
        }

        // If no prayer found today, next is tomorrow's Fajr
        nextPrayer = .fajr
        timeUntilNextPrayer = "tomorrow"
    }
}

// MARK: - CLLocationManagerDelegate

extension PrayerTimeService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            await self.fetchPrayerTimes(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
        }
    }
}

// MARK: - Models

struct PrayerTimes {
    let fajr: Date?
    let sunrise: Date?
    let dhuhr: Date?
    let asr: Date?
    let maghrib: Date?
    let isha: Date?
}

enum Prayer: String, CaseIterable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var icon: String {
        switch self {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.horizon"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        }
    }
}

enum PrayerTimeError: LocalizedError {
    case invalidURL
    case serverError
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .serverError: return "Could not fetch prayer times"
        case .locationUnavailable: return "Location not available"
        }
    }
}

// MARK: - Aladhan API Response

struct AladhanResponse: Codable {
    let data: AladhanData
}

struct AladhanData: Codable {
    let timings: AladhanTimings
}

struct AladhanTimings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String

    func toPrayerTimes() -> PrayerTimes {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let calendar = Calendar.current
        let today = Date()

        func parseTime(_ timeString: String) -> Date? {
            // Remove any timezone info (e.g., "(PKT)")
            let cleanTime = timeString.components(separatedBy: " ").first ?? timeString
            guard let time = formatter.date(from: cleanTime) else { return nil }

            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute

            return calendar.date(from: dateComponents)
        }

        return PrayerTimes(
            fajr: parseTime(Fajr),
            sunrise: parseTime(Sunrise),
            dhuhr: parseTime(Dhuhr),
            asr: parseTime(Asr),
            maghrib: parseTime(Maghrib),
            isha: parseTime(Isha)
        )
    }
}
