import Foundation

public struct LiteLot: Codable, Hashable, Sendable {
    public var name: String
    public var available: Int
    public var total: Int
    
    public init(name: String, available: Int, total: Int) {
        self.name = name
        self.available = available
        self.total = total
    }
}
