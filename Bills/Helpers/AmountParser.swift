import Foundation

struct AmountParser {
    static func parse(from text: String) -> Double? {
        // 尝试匹配 ¥XX.XX 格式
        if let match = text.range(of: "¥?\\s*\\d+\\.\\d{2}", options: .regularExpression) {
            let candidate = String(text[match])
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: "")
            return Double(candidate)
        }
        
        // 尝试匹配 XX.XX元 格式
        if let match = text.range(of: "\\d+\\.\\d{2}\\s*元", options: .regularExpression) {
            let candidate = String(text[match])
                .replacingOccurrences(of: "元", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: "")
            return Double(candidate)
        }
        
        // 尝试匹配 -¥XX.XX 格式（支出）
        if let match = text.range(of: "-\\s*¥?\\s*\\d+\\.\\d{2}", options: .regularExpression) {
            let candidate = String(text[match])
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: "")
            return Double(candidate)
        }
        
        // 尝试匹配纯数字 XX.XX
        if let match = text.range(of: "\\d+\\.\\d{2}", options: .regularExpression) {
            let candidate = String(text[match])
                .replacingOccurrences(of: ",", with: "")
            return Double(candidate)
        }
        
        return nil
    }
}
