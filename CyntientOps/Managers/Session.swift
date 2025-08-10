import Combine
import Foundation

// One source of truth for “who’s signed in”
final class Session: ObservableObject {
    static let shared = Session()

    @Published var user: CoreTypes.User?
    @Published var org: CoreTypes.Organization?

    private init() {}
}