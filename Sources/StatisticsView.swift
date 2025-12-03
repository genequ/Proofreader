import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: TimePeriod = .week
    @State private var monitor: Any?
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .allTime: return nil
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Usage Statistics")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 240)
            }
            
            Divider()
            
            // Statistics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Sessions",
                    value: "\(periodStats.sessions)",
                    icon: "play.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Words Processed",
                    value: formatNumber(periodStats.words),
                    icon: "doc.text.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Corrections",
                    value: "\(periodStats.corrections)",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
            }
            
            Divider()
            
            // All-time statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("All-Time Statistics")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Processing Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTime(appState.statisticsManager.statistics.averageProcessingTime))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated Time Saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTime(appState.statisticsManager.statistics.estimatedTimeSaved))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg Corrections/Session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", appState.statisticsManager.statistics.averageCorrectionsPerSession))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg Words/Session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f", appState.statisticsManager.statistics.averageWordsPerSession))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                    }
                }
                
                if let firstUse = appState.statisticsManager.statistics.firstUseDate {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Use")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(firstUse))
                                .font(.system(.caption, design: .rounded))
                        }
                        
                        Spacer()
                        
                        if let lastUse = appState.statisticsManager.statistics.lastUseDate {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Last Use")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(lastUse))
                                    .font(.system(.caption, design: .rounded))
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button("Reset Statistics") {
                    appState.statisticsManager.reset()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 600, height: 480)
        .onAppear {
            setupKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }
    
    private var periodStats: (sessions: Int, words: Int, corrections: Int) {
        if let days = selectedPeriod.days {
            return appState.statisticsManager.statistics(forLastDays: days)
        } else {
            return (
                appState.statisticsManager.statistics.totalSessions,
                appState.statisticsManager.statistics.totalWordsProcessed,
                appState.statisticsManager.statistics.totalCorrections
            )
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(Int(seconds))s"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func setupKeyMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC key
                dismiss()
                return nil
            }
            return event
        }
    }
    
    private func removeKeyMonitor() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(AppState())
}
