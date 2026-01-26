import Foundation

/// Represents usage statistics for the application
struct UsageStatistics: Codable {
    var totalCorrections: Int = 0
    var totalWordsProcessed: Int = 0
    var totalCharactersProcessed: Int = 0
    var totalSessions: Int = 0
    var totalErrors: Int = 0
    var averageProcessingTime: TimeInterval = 0
    var firstUseDate: Date?
    var lastUseDate: Date?

    // Session history (last 100 sessions)
    var recentSessions: [ProofreadingSession] = []
    
    mutating func recordSession(_ session: ProofreadingSession) {
        totalSessions += 1
        totalWordsProcessed += session.wordCount
        totalCharactersProcessed += session.characterCount
        totalCorrections += session.correctionCount
        
        // Update average processing time
        let totalTime = averageProcessingTime * Double(totalSessions - 1) + session.processingTime
        averageProcessingTime = totalTime / Double(totalSessions)
        
        // Update dates
        if firstUseDate == nil {
            firstUseDate = session.date
        }
        lastUseDate = session.date
        
        // Add to recent sessions (keep last 100)
        recentSessions.append(session)
        if recentSessions.count > 100 {
            recentSessions.removeFirst()
        }
    }
    
    mutating func recordError() {
        totalErrors += 1
    }
    
    var estimatedTimeSaved: TimeInterval {
        // Estimate: 1 minute saved per 100 words proofread
        return Double(totalWordsProcessed) / 100.0 * 60.0
    }
    
    var averageCorrectionsPerSession: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(totalCorrections) / Double(totalSessions)
    }
    
    var averageWordsPerSession: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(totalWordsProcessed) / Double(totalSessions)
    }
}

/// Represents a single proofreading session
struct ProofreadingSession: Codable, Identifiable {
    let id: String
    let date: Date
    let wordCount: Int
    let characterCount: Int
    let correctionCount: Int
    let processingTime: TimeInterval
    let modelUsed: String
    let success: Bool
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        wordCount: Int,
        characterCount: Int,
        correctionCount: Int,
        processingTime: TimeInterval,
        modelUsed: String,
        success: Bool = true
    ) {
        self.id = id
        self.date = date
        self.wordCount = wordCount
        self.characterCount = characterCount
        self.correctionCount = correctionCount
        self.processingTime = processingTime
        self.modelUsed = modelUsed
        self.success = success
    }
}

/// Manages usage statistics persistence and tracking
@MainActor
class StatisticsManager: ObservableObject {
    @Published var statistics: UsageStatistics

    private let statisticsKey = "usageStatistics"
    private let userDefaults = UserDefaults.standard
    private var saveTask: Task<Void, Never>?
    private let saveDebounceDelay: TimeInterval = 2.0  // Debounce saves by 2 seconds

    init() {
        // Load existing statistics
        if let data = userDefaults.data(forKey: statisticsKey),
           let stats = try? JSONDecoder().decode(UsageStatistics.self, from: data) {
            self.statistics = stats
        } else {
            self.statistics = UsageStatistics()
        }
    }

    /// Save statistics to persistent storage (debounced)
    func save() {
        // Cancel any pending save
        saveTask?.cancel()

        // Schedule a new save after delay
        saveTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(saveDebounceDelay * 1_000_000_000))
            } catch {
                return
            }

            if !Task.isCancelled {
                if let data = try? JSONEncoder().encode(statistics) {
                    userDefaults.set(data, forKey: statisticsKey)
                }
            }
        }
    }

    /// Force immediate save (use when app is quitting)
    func forceSave() {
        saveTask?.cancel()
        if let data = try? JSONEncoder().encode(statistics) {
            userDefaults.set(data, forKey: statisticsKey)
        }
    }

    /// Record a proofreading session
    func recordSession(
        originalText: String,
        correctedText: String,
        processingTime: TimeInterval,
        modelUsed: String,
        success: Bool = true
    ) {
        let wordCount = originalText.split(separator: " ").count
        let characterCount = originalText.count
        let correctionCount = estimateCorrections(original: originalText, corrected: correctedText)

        let session = ProofreadingSession(
            wordCount: wordCount,
            characterCount: characterCount,
            correctionCount: correctionCount,
            processingTime: processingTime,
            modelUsed: modelUsed,
            success: success
        )

        statistics.recordSession(session)
        save()  // Debounced save
    }

    /// Record an error
    func recordError() {
        statistics.recordError()
        save()  // Debounced save
    }

    /// Reset all statistics
    func reset() {
        statistics = UsageStatistics()
        forceSave()  // Immediate save for reset
    }

    /// Estimate number of corrections made using character-level diff
    private func estimateCorrections(original: String, corrected: String) -> Int {
        // Normalize texts to avoid counting trailing whitespace as corrections
        let normalizedOriginal = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCorrected = corrected.trimmingCharacters(in: .whitespacesAndNewlines)

        // If texts are the same after normalization, no corrections
        if normalizedOriginal == normalizedCorrected {
            return 0
        }

        // Use the same LCS algorithm from DiffHighlightView for accurate counting
        let originalChars = Array(normalizedOriginal)
        let correctedChars = Array(normalizedCorrected)

        let diff = longestCommonSubsequence(originalChars, correctedChars)

        // Count insertions + deletions as corrections (excluding trailing whitespace)
        var corrections = 0
        for operation in diff {
            switch operation {
            case .delete(let length):
                corrections += length
            case .insert(let length):
                corrections += length
            case .equal:
                break
            }
        }

        // Normalize by word count for better estimation
        let wordCount = max(normalizedOriginal.split(separator: " ").count, 1)
        return min(corrections / wordCount, wordCount)  // Cap at word count
    }

    /// Longest Common Subsequence algorithm for diff calculation
    private func longestCommonSubsequence<T: Equatable>(_ a: [T], _ b: [T]) -> [LCSOperation] {
        let m = a.count
        let n = b.count

        var lcs = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1...m {
            for j in 1...n {
                if a[i-1] == b[j-1] {
                    lcs[i][j] = lcs[i-1][j-1] + 1
                } else {
                    lcs[i][j] = max(lcs[i-1][j], lcs[i][j-1])
                }
            }
        }

        var operations: [LCSOperation] = []
        var i = m, j = n

        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] {
                var equalCount = 1
                i -= 1
                j -= 1

                while i > 0 && j > 0 && a[i-1] == b[j-1] {
                    equalCount += 1
                    i -= 1
                    j -= 1
                }

                operations.append(.equal(equalCount))
            } else if lcs[i-1][j] > lcs[i][j-1] {
                operations.append(.delete(1))
                i -= 1
            } else {
                operations.append(.insert(1))
                j -= 1
            }
        }

        while i > 0 {
            operations.append(.delete(1))
            i -= 1
        }

        while j > 0 {
            operations.append(.insert(1))
            j -= 1
        }

        return operations.reversed()
    }

    /// Local operation enum for LCS algorithm (avoids conflicts with DiffHighlightView)
    private enum LCSOperation {
        case equal(Int)
        case delete(Int)
        case insert(Int)
    }
    
    /// Get sessions from the last N days
    func sessions(fromLastDays days: Int) -> [ProofreadingSession] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return statistics.recentSessions.filter { $0.date >= cutoffDate }
    }
    
    /// Get statistics for the last N days
    func statistics(forLastDays days: Int) -> (sessions: Int, words: Int, corrections: Int) {
        let recentSessions = sessions(fromLastDays: days)
        let sessions = recentSessions.count
        let words = recentSessions.reduce(0) { $0 + $1.wordCount }
        let corrections = recentSessions.reduce(0) { $0 + $1.correctionCount }
        return (sessions, words, corrections)
    }
}
