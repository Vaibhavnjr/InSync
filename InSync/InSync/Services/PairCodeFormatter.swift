import Foundation

enum PairCodeFormatter {
    static func normalize(_ input: String) -> String {
        let cleaned = input
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }

        guard cleaned.count > 4 else { return cleaned }

        let word = cleaned.prefix(cleaned.count - 4)
        let digits = cleaned.suffix(4)

        return "\(word)-\(digits)"
    }

    static func generate() -> String {
        let word = Constants.pairWords.randomElement() ?? "LOVE"
        let digits = Int.random(in: 1000...9999)
        return "\(word)-\(digits)"
    }
}

