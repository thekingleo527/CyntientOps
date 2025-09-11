import Foundation

public struct WeatherTaskItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let affectedBy: String
    public let recommendation: String

    public init(id: String, title: String, affectedBy: String, recommendation: String) {
        self.id = id
        self.title = title
        self.affectedBy = affectedBy
        self.recommendation = recommendation
    }
}

