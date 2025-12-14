// RecommendationsViewModel.swift
// NoorReader
//
// ViewModel for AI study recommendations UI

import Foundation
import SwiftData

/// ViewModel for managing study recommendations state
@MainActor
@Observable
final class RecommendationsViewModel {

    // MARK: - Properties

    private let recommendationService: StudyRecommendationService
    private var modelContext: ModelContext?

    // State
    var isLoading = false
    var currentPlan: StudyPlan?
    var weakAreas: [WeakArea] = []
    var error: Error?
    var showError = false

    // Filters
    var selectedPriority: FlashcardRecommendation.ReviewPriority?
    var showAllFlashcards = false

    // MARK: - Computed Properties

    var hasPlan: Bool {
        currentPlan != nil
    }

    var flashcardRecommendations: [FlashcardRecommendation] {
        guard let plan = currentPlan else { return [] }

        var cards = plan.suggestedFlashcards

        // Filter by priority if selected
        if let priority = selectedPriority {
            cards = cards.filter { $0.priority == priority }
        }

        // Limit unless showing all
        if !showAllFlashcards {
            cards = Array(cards.prefix(10))
        }

        return cards
    }

    var criticalCount: Int {
        currentPlan?.suggestedFlashcards.filter { $0.priority == .critical }.count ?? 0
    }

    var highPriorityCount: Int {
        currentPlan?.suggestedFlashcards.filter { $0.priority == .high }.count ?? 0
    }

    var normalCount: Int {
        currentPlan?.suggestedFlashcards.filter { $0.priority == .normal }.count ?? 0
    }

    var totalRecommendedCards: Int {
        currentPlan?.suggestedFlashcards.count ?? 0
    }

    var readingSuggestions: [ReadingSuggestion] {
        currentPlan?.suggestedReadingSections ?? []
    }

    var focusAreas: [FocusArea] {
        currentPlan?.focusAreas ?? []
    }

    var motivationalMessage: String {
        currentPlan?.motivationalMessage ?? "Begin your study journey with Bismillah."
    }

    var estimatedStudyTime: String {
        currentPlan?.formattedDuration ?? "0m"
    }

    var prayerSuggestion: PrayerTimeStudySuggestion? {
        currentPlan?.prayerTimeOptimization
    }

    var hasWeakAreas: Bool {
        !weakAreas.isEmpty
    }

    var topWeakAreas: [WeakArea] {
        Array(weakAreas.prefix(3))
    }

    // MARK: - Initialization

    init() {
        self.recommendationService = StudyRecommendationService.shared
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        recommendationService.configure(modelContext: modelContext)
    }

    // MARK: - Plan Generation

    func loadPlan() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            try await recommendationService.generateDailyPlan()
            currentPlan = recommendationService.currentPlan
            weakAreas = recommendationService.weakAreas
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    func refreshPlan() async {
        await recommendationService.refreshPlan()
        currentPlan = recommendationService.currentPlan
        weakAreas = recommendationService.weakAreas
    }

    // MARK: - Prayer Time Integration

    func updateForPrayerTime(nextPrayer: String, minutesUntil: Double) async {
        await recommendationService.updatePrayerTimeSuggestion(
            nextPrayer: nextPrayer,
            timeUntilPrayer: minutesUntil * 60
        )
        currentPlan = recommendationService.currentPlan
    }

    // MARK: - Filters

    func filterByPriority(_ priority: FlashcardRecommendation.ReviewPriority?) {
        selectedPriority = priority
    }

    func toggleShowAllFlashcards() {
        showAllFlashcards.toggle()
    }

    func clearFilters() {
        selectedPriority = nil
        showAllFlashcards = false
    }

    // MARK: - Actions

    func getFlashcardIDs(for priority: FlashcardRecommendation.ReviewPriority? = nil) -> [UUID] {
        guard let plan = currentPlan else { return [] }

        if let priority {
            return plan.suggestedFlashcards
                .filter { $0.priority == priority }
                .map(\.flashcardID)
        }

        return plan.suggestedFlashcards.map(\.flashcardID)
    }

    func getOptimalStudyTime() async -> (hour: Int, minute: Int) {
        let components = await recommendationService.getOptimalStudyTime()
        return (components.hour ?? 9, components.minute ?? 0)
    }
}

// MARK: - Summary Statistics

extension RecommendationsViewModel {

    struct PlanSummary {
        let totalCards: Int
        let criticalCards: Int
        let readingSuggestions: Int
        let focusAreas: Int
        let estimatedMinutes: Int

        var needsUrgentAttention: Bool {
            criticalCards > 0
        }

        var summaryText: String {
            var parts: [String] = []

            if criticalCards > 0 {
                parts.append("\(criticalCards) critical")
            }

            if totalCards > criticalCards {
                parts.append("\(totalCards - criticalCards) other cards")
            }

            if readingSuggestions > 0 {
                parts.append("\(readingSuggestions) reading suggestions")
            }

            return parts.joined(separator: ", ")
        }
    }

    var planSummary: PlanSummary {
        PlanSummary(
            totalCards: totalRecommendedCards,
            criticalCards: criticalCount,
            readingSuggestions: readingSuggestions.count,
            focusAreas: focusAreas.count,
            estimatedMinutes: Int((currentPlan?.estimatedDuration ?? 0) / 60)
        )
    }
}
