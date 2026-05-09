import SwiftUI

struct DiffHighlightView: View {
    let originalText: String
    let correctedText: String
    let highlightIntensity: Double // 0.0 to 1.0

    // Async diff state
    @State private var highlightedOriginal: AttributedString?
    @State private var highlightedCorrected: AttributedString?
    @State private var computedKey: String = ""

    // MARK: - Highlight Constants
    private struct HighlightColors {
        static let deletionBackgroundAlpha: Double = 0.25
        static let deletionForegroundAlpha: Double = 0.8
        static let insertionBackgroundAlpha: Double = 0.25
        static let insertionForegroundAlpha: Double = 0.9
        static let insertionGreen: Color = .green
        static let deletionRed: Color = .red
    }

    private var cacheKey: String {
        "\(originalText.count)-\(correctedText.count)-\(originalText.prefix(16))-\(correctedText.prefix(16))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !originalText.isEmpty && !correctedText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original:")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            if let highlighted = highlightedOriginal {
                                Text(highlighted)
                                    .textSelection(.enabled)
                                    .lineSpacing(2)
                            } else {
                                Text(originalText)
                                    .textSelection(.enabled)
                                    .lineSpacing(2)
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Corrected:")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            if let highlighted = highlightedCorrected {
                                Text(highlighted)
                                    .textSelection(.enabled)
                                    .lineSpacing(2)
                            } else {
                                Text(correctedText)
                                    .textSelection(.enabled)
                                    .lineSpacing(2)
                            }
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                } else {
                    Text(correctedText)
                        .textSelection(.enabled)
                        .lineSpacing(2)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .onAppear {
            computeDiffIfNeeded()
        }
        .onChange(of: cacheKey) { _, _ in
            highlightedOriginal = nil
            highlightedCorrected = nil
            computeDiffIfNeeded()
        }
    }

    private func computeDiffIfNeeded() {
        guard cacheKey != computedKey else { return }
        let key = cacheKey
        let orig = originalText
        let corr = correctedText
        let intensity = highlightIntensity

        Task.detached {
            let differences = Self.computeDifferences(original: orig, corrected: corr)
            let origAttr = Self.createAttributedString(for: orig, isOriginal: true, differences: differences, intensity: intensity)
            let corrAttr = Self.createAttributedString(for: corr, isOriginal: false, differences: differences, intensity: intensity)

            await MainActor.run {
                guard key == cacheKey else { return }
                self.highlightedOriginal = origAttr
                self.highlightedCorrected = corrAttr
                self.computedKey = key
            }
        }
    }

    // MARK: - Thread-safe static methods for background computation

    private static func computeDifferences(original: String, corrected: String) -> [TextDifference] {
        let originalChars = Array(original)
        let correctedChars = Array(corrected)
        let diff = Self.longestCommonSubsequence(originalChars, correctedChars)
        var differences: [TextDifference] = []
        var originalIndex = 0
        var correctedIndex = 0

        for operation in diff {
            switch operation {
            case .equal(let length):
                originalIndex += length
                correctedIndex += length
            case .delete(let length):
                let range = NSRange(location: originalIndex, length: length)
                let text = String(originalChars[originalIndex..<originalIndex + length])
                differences.append(.deletion(range, text))
                originalIndex += length
            case .insert(let length):
                let range = NSRange(location: correctedIndex, length: length)
                let text = String(correctedChars[correctedIndex..<correctedIndex + length])
                differences.append(.insertion(range, text))
                correctedIndex += length
            }
        }
        return filterTrailingWhitespaceDifferences(differences, in: original)
    }

    private static func createAttributedString(for text: String, isOriginal: Bool, differences: [TextDifference], intensity: Double) -> AttributedString {
        var attributedString = AttributedString(text)

        if isOriginal {
            for diff in differences {
                if case .deletion(let range, _) = diff {
                    applyHighlight(to: &attributedString, in: range, text: text, isDeletion: true, intensity: intensity)
                }
            }
        } else {
            for diff in differences {
                if case .insertion(let range, _) = diff {
                    applyHighlight(to: &attributedString, in: range, text: text, isDeletion: false, intensity: intensity)
                }
            }
        }
        return attributedString
    }

    private static func applyHighlight(to attributedString: inout AttributedString, in range: NSRange, text: String, isDeletion: Bool, intensity: Double) {
        guard let range = Range(range, in: text) else { return }

        let startOffset = range.lowerBound.utf16Offset(in: text)
        let endOffset = range.upperBound.utf16Offset(in: text)

        guard startOffset < attributedString.characters.count,
              endOffset <= attributedString.characters.count,
              startOffset < endOffset else { return }

        guard startOffset <= attributedString.characters.count - 1,
              endOffset <= attributedString.characters.count else { return }

        let start = attributedString.index(attributedString.startIndex, offsetByCharacters: startOffset)
        let end = attributedString.index(attributedString.startIndex, offsetByCharacters: endOffset)

        guard start < end else { return }

        if isDeletion {
            attributedString[start..<end].backgroundColor = HighlightColors.deletionRed.opacity(intensity * HighlightColors.deletionBackgroundAlpha)
            attributedString[start..<end].foregroundColor = HighlightColors.deletionRed.opacity(HighlightColors.deletionForegroundAlpha)
            attributedString[start..<end].strikethroughStyle = .single
        } else {
            attributedString[start..<end].backgroundColor = HighlightColors.insertionGreen.opacity(intensity * HighlightColors.insertionBackgroundAlpha)
            attributedString[start..<end].foregroundColor = HighlightColors.insertionGreen.opacity(HighlightColors.insertionForegroundAlpha)
            attributedString[start..<end].font = .body.weight(.medium)
            attributedString[start..<end].underlineStyle = .single
        }
    }

    /// Extract only the changed portions from a diff result
    static func extractChanges(from differences: [TextDifference], correctedText: String, originalText: String) -> String {
        // If texts are effectively the same (ignoring trailing whitespace), return empty
        let normalizedOriginal = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCorrected = correctedText.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedOriginal == normalizedCorrected {
            return ""
        }

        var changes: [String] = []
        var currentChange = ""
        var inChange = false

        for diff in differences {
            switch diff {
            case .insertion(_, let text):
                // Skip whitespace-only insertions
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

                if !inChange {
                    inChange = true
                    currentChange = ""
                }
                currentChange += text
            case .deletion:
                // Skip deletions in the changes output
                if inChange && !currentChange.isEmpty {
                    changes.append(currentChange)
                    currentChange = ""
                    inChange = false
                }
            }
        }

        // Add any remaining change
        if inChange && !currentChange.isEmpty {
            changes.append(currentChange)
        }

        // If no changes detected but texts differ, return the corrected text
        if changes.isEmpty && normalizedOriginal != normalizedCorrected {
            return correctedText
        }

        return changes.joined(separator: "\n")
    }

    private static func findDifferences(original: String, corrected: String) -> [TextDifference] {
        // Use character-level comparison on original text (don't normalize - breaks range mapping)
        let originalChars = Array(original)
        let correctedChars = Array(corrected)

        let diff = Self.longestCommonSubsequence(originalChars, correctedChars)
        var differences: [TextDifference] = []

        var originalIndex = 0
        var correctedIndex = 0

        for operation in diff {
            switch operation {
            case .equal(let length):
                originalIndex += length
                correctedIndex += length

            case .delete(let length):
                let range = NSRange(location: originalIndex, length: length)
                let text = String(originalChars[originalIndex..<originalIndex + length])
                differences.append(.deletion(range, text))
                originalIndex += length

            case .insert(let length):
                let range = NSRange(location: correctedIndex, length: length)
                let text = String(correctedChars[correctedIndex..<correctedIndex + length])
                differences.append(.insertion(range, text))
                correctedIndex += length
            }
        }

        // Post-process: filter out trailing-only whitespace changes
        return filterTrailingWhitespaceDifferences(differences, in: original)
    }

    private static func filterTrailingWhitespaceDifferences(_ differences: [TextDifference], in text: String) -> [TextDifference] {
        // Find the last non-whitespace character position
        let lastNonWhitespaceIndex = text.lastIndex { !$0.isWhitespace }

        guard let lastIndex = lastNonWhitespaceIndex else {
            // Text is all whitespace, return all differences
            return differences
        }

        let lastContentPosition = text.distance(from: text.startIndex, to: lastIndex)

        // Filter out differences that occur entirely after the last content
        return differences.filter { diff in
            switch diff {
            case .deletion(let range, _):
                return range.location < lastContentPosition
            case .insertion(let range, _):
                return range.location < lastContentPosition
            }
        }
    }
    
    // Longest Common Subsequence algorithm for diff calculation
    private static func longestCommonSubsequence<T: Equatable>(_ a: [T], _ b: [T]) -> [DiffOperation] {
        let m = a.count
        let n = b.count
        
        // Create LCS table
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
        
        // Backtrack to build diff operation sequence
        var operations: [DiffOperation] = []
        var i = m, j = n

        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] {
                // Found identical character block
                var equalCount = 1
                i -= 1
                j -= 1

                // Calculate count of consecutive identical characters
                while i > 0 && j > 0 && a[i-1] == b[j-1] {
                    equalCount += 1
                    i -= 1
                    j -= 1
                }

                operations.append(.equal(equalCount))
            } else if lcs[i-1][j] > lcs[i][j-1] {
                // Deletion operation
                operations.append(.delete(1))
                i -= 1
            } else if lcs[i][j-1] > lcs[i-1][j] {
                // Insertion operation
                operations.append(.insert(1))
                j -= 1
            } else {
                // Equal values - prefer to look ahead for matches rather than arbitrary choice
                // Look for the next match in either direction
                let nextMatchInA = findNextMatchIndex(in: a, target: b[j-1], from: i-1)
                let nextMatchInB = findNextMatchIndex(in: b, target: a[i-1], from: j-1)

                // Choose the direction with the closer match
                if let matchA = nextMatchInA, let matchB = nextMatchInB {
                    if (i - 1 - matchA) <= (j - 1 - matchB) {
                        operations.append(.delete(1))
                        i -= 1
                    } else {
                        operations.append(.insert(1))
                        j -= 1
                    }
                } else if nextMatchInA != nil {
                    operations.append(.delete(1))
                    i -= 1
                } else {
                    operations.append(.insert(1))
                    j -= 1
                }
            }
        }
        
        // Handle remaining characters
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

    /// Find the index of the next occurrence of target in array, starting from startIndex and going backward
    private static func findNextMatchIndex<T: Equatable>(in array: [T], target: T, from startIndex: Int) -> Int? {
        for i in stride(from: startIndex, through: 0, by: -1) {
            if array[i] == target {
                return i
            }
        }
        return nil
    }
}

enum DiffOperation {
    case equal(Int)
    case delete(Int)
    case insert(Int)
}
enum TextDifference {
    case insertion(NSRange, String)
    case deletion(NSRange, String)
}