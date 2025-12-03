import SwiftUI

struct DiffHighlightView: View {
    let originalText: String
    let correctedText: String
    let highlightIntensity: Double // 0.0 to 1.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !originalText.isEmpty && !correctedText.isEmpty {
                    // Show diff comparison
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(createAttributedString(for: originalText, isOriginal: true))
                                .textSelection(.enabled)
                                .lineSpacing(2) // Better reading experience
                                .padding(12)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Corrected:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(createAttributedString(for: correctedText, isOriginal: false))
                                .textSelection(.enabled)
                                .lineSpacing(2) // Better reading experience
                                .padding(12)
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                } else {
                    // If no original text, only show corrected results
                    Text(correctedText)
                        .textSelection(.enabled)
                        .lineSpacing(2) // Better reading experience
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
    }
    
    private func createAttributedString(for text: String, isOriginal: Bool) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // If both original and corrected text exist, perform diff comparison
        if !originalText.isEmpty && !correctedText.isEmpty {
            let differences = findDifferences(original: originalText, corrected: correctedText)
            
            if isOriginal {
                // Mark deleted parts in original text (subtle red)
                for diff in differences {
                    if case .deletion(let range, _) = diff {
                        if let range = Range(range, in: text) {
                            let start = attributedString.index(attributedString.startIndex, offsetByCharacters: range.lowerBound.utf16Offset(in: text))
                            let end = attributedString.index(attributedString.startIndex, offsetByCharacters: range.upperBound.utf16Offset(in: text))
                            if start < attributedString.endIndex && end <= attributedString.endIndex {
                                attributedString[start..<end].backgroundColor = Color.red.opacity(highlightIntensity)
                                attributedString[start..<end].foregroundColor = Color.red.opacity(0.8)
                            }
                        }
                    }
                }
            } else {
                // Mark added parts in corrected text (subtle green)
                for diff in differences {
                    if case .insertion(let range, _) = diff {
                        if let range = Range(range, in: text) {
                            let start = attributedString.index(attributedString.startIndex, offsetByCharacters: range.lowerBound.utf16Offset(in: text))
                            let end = attributedString.index(attributedString.startIndex, offsetByCharacters: range.upperBound.utf16Offset(in: text))
                            if start < attributedString.endIndex && end <= attributedString.endIndex {
                                attributedString[start..<end].backgroundColor = Color.green.opacity(highlightIntensity)
                                attributedString[start..<end].foregroundColor = Color.green.opacity(0.9)
                                attributedString[start..<end].font = .body.weight(.medium)
                            }
                        }
                    }
                }
            }
        }
        
        return attributedString
    }
    
    private func findDifferences(original: String, corrected: String) -> [TextDifference] {
        // Use more precise character-level comparison
        let originalChars = Array(original)
        let correctedChars = Array(corrected)
        
        let diff = longestCommonSubsequence(originalChars, correctedChars)
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
        
        return differences
    }
    
    // Longest Common Subsequence algorithm for diff calculation
    private func longestCommonSubsequence<T: Equatable>(_ a: [T], _ b: [T]) -> [DiffOperation] {
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
                var deleteCount = 1
                i -= 1
                
                // Calculate count of consecutive deleted characters
                while i > 0 && (j == 0 || lcs[i-1][j] >= lcs[i][j-1]) {
                    deleteCount += 1
                    i -= 1
                }
                
                operations.append(.delete(deleteCount))
            } else {
                // Insertion operation
                var insertCount = 1
                j -= 1
                
                // Calculate count of consecutive inserted characters
                while j > 0 && (i == 0 || lcs[i][j-1] > lcs[i-1][j]) {
                    insertCount += 1
                    j -= 1
                }
                
                operations.append(.insert(insertCount))
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