import Foundation

enum AppConfig {
    /// Base URL of the deployed ASP.NET Core Web API (Part 1).
    /// For a local API use "http://localhost:5080" (the simulator can reach your Mac's localhost),
    /// and add an App Transport Security exception for HTTP.
    static let apiBaseURL = URL(string: "https://municipal-elections-a1-fgdtgnewg7cedkd7.westus3-01.azurewebsites.net")!

    /// Must match the API's Identity password rule (RequiredLength = 6).
    static let minimumPasswordLength = 6
}
