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
    
    // Error type tracking
    var grammarCorrections: Int = 0
    var spellingCorrections: Int = 0
    var punctuationCorrections: Int = 0
    var styleCorrections: Int = 0
    
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
    
    init() {
        // Load existing statistics
        if let data = userDefaults.data(forKey: statisticsKey),
           let stats = try? JSONDecoder().decode(UsageStatistics.self, from: data) {
            self.statistics = stats
        } else {
            self.statistics = UsageStatistics()
        }
    }
    
    /// Save statistics to persistent storage
    func save() {
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
        save()
    }
    
    /// Record an error
    func recordError() {
        statistics.recordError()
        save()
    }
    
    /// Reset all statistics
    func reset() {
        statistics = UsageStatistics()
        save()
    }
    
    /// Estimate number of corrections made
    private func estimateCorrections(original: String, corrected: String) -> Int {
        let originalWords = original.split(separator: " ")
        let correctedWords = corrected.split(separator: " ")
        
        // Simple estimation: count different words
        var corrections = 0
        let maxCount = max(originalWords.count, correctedWords.count)
        
        for i in 0..<maxCount {
            let origWord = i < originalWords.count ? String(originalWords[i]) : ""
            let corrWord = i < correctedWords.count ? String(correctedWords[i]) : ""
            
            if origWord != corrWord {
                corrections += 1
            }
        }
        
        return corrections
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
