import SwiftUI

struct DiffHighlightView: View {
    let originalText: String
    let correctedText: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !originalText.isEmpty && !correctedText.isEmpty {
                    // 显示差异比较
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(createAttributedString(for: originalText, isOriginal: true))
                                .textSelection(.enabled)
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
                    // 如果没有原文，只显示校对结果
                    Text(correctedText)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
    }
    
    private func createAttributedString(for text: String, isOriginal: Bool) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // 如果有原文和校对文本，进行差异比较
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
                                attributedString[start..<end].backgroundColor = Color.red.opacity(0.2)
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
                                attributedString[start..<end].backgroundColor = Color.green.opacity(0.25)
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
        // 使用更精确的字符级比较
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
    
    // 最长公共子序列算法用于计算差异
    private func longestCommonSubsequence<T: Equatable>(_ a: [T], _ b: [T]) -> [DiffOperation] {
        let m = a.count
        let n = b.count
        
        // 创建 LCS 表
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
        
        // 回溯构建差异操作序列
        var operations: [DiffOperation] = []
        var i = m, j = n
        
        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] {
                // 找到相同的字符块
                var equalCount = 1
                i -= 1
                j -= 1
                
                // 计算连续相同字符的数量
                while i > 0 && j > 0 && a[i-1] == b[j-1] {
                    equalCount += 1
                    i -= 1
                    j -= 1
                }
                
                operations.append(.equal(equalCount))
            } else if lcs[i-1][j] > lcs[i][j-1] {
                // 删除操作
                var deleteCount = 1
                i -= 1
                
                // 计算连续删除字符的数量
                while i > 0 && (j == 0 || lcs[i-1][j] >= lcs[i][j-1]) {
                    deleteCount += 1
                    i -= 1
                }
                
                operations.append(.delete(deleteCount))
            } else {
                // 插入操作
                var insertCount = 1
                j -= 1
                
                // 计算连续插入字符的数量
                while j > 0 && (i == 0 || lcs[i][j-1] > lcs[i-1][j]) {
                    insertCount += 1
                    j -= 1
                }
                
                operations.append(.insert(insertCount))
            }
        }
        
        // 处理剩余的字符
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