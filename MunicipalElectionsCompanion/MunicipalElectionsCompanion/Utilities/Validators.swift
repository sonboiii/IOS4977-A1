import Foundation

enum Validators {
    static func required(_ value: String, field: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(field) is required." : nil
    }

    static func email(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Email is required." }
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) == nil
            ? "Enter a valid email address."
            : nil
    }

    static func password(_ value: String) -> String? {
        if value.isEmpty { return "Password is required." }
        return value.count < AppConfig.minimumPasswordLength
            ? "Password must be at least \(AppConfig.minimumPasswordLength) characters."
            : nil
    }
}
