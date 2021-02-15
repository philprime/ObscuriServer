import Foundation
import os.log
import Combine
import Network
import ObscuriCore

class ConnectionManager {

    // MARK: - Services

    weak var delegate: ConnectionManagerDelegate?

    // MARK: - Properties

    private(set) var connectionsById: [String: Connection] = [:]

    // MARK: - Life Cycle

    func stop() {
        for connection in connectionsById.values {
            connection.networkConnection.stateUpdateHandler = nil
            connection.networkConnection.cancel()
        }
        connectionsById.removeAll()
    }

    // MARK: - Methods

    func add(connection: NWConnection) {
        let con = Connection(networkConnection: connection)
        os_log("adding connection with id %@", log: .obscuri, type: .debug, con.id)
        connectionsById[con.id] = con
        connection.stateUpdateHandler = { state in
            switch state {
            case .preparing:
                os_log("connection %@ is begin established", log: .obscuri, type: .info, con.id)
            case .setup:
                os_log("connection %@ is initialized", log: .obscuri, type: .info, con.id)
            case .ready:
                os_log("connection %@ is ready for communication", log: .obscuri, type: .info, con.id)
            case .failed(let error):
                os_log("connection %@ failed, reason: %@", log: .obscuri, type: .info, con.id, error.localizedDescription)
                self.close(connection: con)
            case .waiting(let error):
                os_log("connection %@ is waiting, reason: %@", log: .obscuri, type: .info, con.id, error.localizedDescription)
            case .cancelled:
                os_log("connection %@ cancelled", log: .obscuri, type: .info, con.id)
                self.close(connection: con)
            default:
                break
            }
        }
        connection.start(queue: .connectionManagerQueue)
        delegate?.connectionManager(self, didAddConnection: con)
    }

    func close(connection: Connection) {
        os_log("closing connection with id %@", log: .obscuri, type: .debug, connection.id)
        connection.networkConnection.cancel()
        connectionsById.removeValue(forKey: connection.id)
        connection.networkConnection.cancel()
        delegate?.connectionManager(self, didCloseConnection: connection)
    }
}

extension DispatchQueue {

    static let connectionManagerQueue = DispatchQueue(label: "com.techprimate.Obscuri.Server.ConnectionManager", target: .obscuriQueue)
}
