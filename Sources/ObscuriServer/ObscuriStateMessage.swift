import Foundation

public struct ObscuriStateMessage<State: Codable>: Codable {

    // MARK: - Properties

    public let timestamp: Date
    public let action: String
    public let state: State

    // MARK: - Initializers

    public init(timestamp: Date, action: String, state: State) {
        self.timestamp = timestamp
        self.action = action
        self.state = state
    }
}
