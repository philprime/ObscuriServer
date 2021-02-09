import Foundation
import os.log

@available(OSX 10.12, *)
class ConnectionManager {

    // MARK: - Services

    private let logger = OSLog(subsystem: LoggingConfig.identifier, category: String(describing: ConnectionManager.self))

    // MARK: - Properties

    var connections: [Connection] = []

    // MARK: - Methods

    func add(connection: Connection) {
        os_log("adding connection with id %@", log: logger, type: .debug, connection.id)
        connections.append(connection)
    }

    func close(connection: Connection) {
        os_log("closing connection with id %@", log: logger, type: .debug, connection.id)
        connection.outputStream.close()
        connections = connections.filter { $0.id != connection.id }
    }
}
