import Foundation
import os.log
import Combine

@available(OSX 10.12, *)
class ConnectionManager {

    // MARK: - Services

    weak var delegate: ConnectionManagerDelegate?

    private let logger = OSLog(subsystem: LoggingConfig.identifier, category: String(describing: ConnectionManager.self))

    // MARK: - Properties

    private(set) var connections: [Connection] = []

    // MARK: - Methods

    func add(connection: Connection) {
        os_log("adding connection with id %@", log: logger, type: .debug, connection.id)
        connections.append(connection)
        delegate?.connectionManager(self, didAddConnection: connection)
    }

    func close(connection: Connection) {
        os_log("closing connection with id %@", log: logger, type: .debug, connection.id)
        connection.outputStream.close()
        let closingConnections = connections.filter { $0.id == connection.id }
        connections = connections.filter { $0.id != connection.id }
        for connection in closingConnections {
            delegate?.connectionManager(self, didCloseConnection: connection)
        }
    }
}
