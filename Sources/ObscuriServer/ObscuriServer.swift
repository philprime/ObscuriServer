import Foundation
import os.log
import JSONOverTCP
import Network
import ObscuriCore

@available(OSX 10.12, *)
public class ObscuriServer {

    // MARK: - Services

    private lazy var connectionManager: ConnectionManager = {
        let manager = ConnectionManager()
        manager.delegate = self
        return manager
    }()

    // MARK: - Properties

    public weak var delegate: ObscuriServerDelegate?

    private let serviceId: String
    private let serviceName: String
    private let listener: NWListener

    // MARK: - Intializer

    public init(serviceId: String = UUID().uuidString, serviceName: String) throws {
        self.serviceId = serviceId
        self.serviceName = serviceName

        // Inform user about service name limitations
        if serviceName.contains(".") {
            os_log("Attention: the service name contains a dot which is usually used for declaring subdomains. This might lead to issues during discovery!", log: .obscuri, type: .info)
        }

        let parameters = ObscuriServer.getTLSParameters(allowInsecure: true, queue: .obscuriQueue)
        listener = try NWListener(using: parameters)
        let  service = NWListener.Service(name: serviceName, type: ObscuriDefinition.serviceType, domain: ObscuriDefinition.serviceDomain, txtRecord: txtRecordData)
        listener.service = service

        listener.stateUpdateHandler = self.didUpdateState(to:)
        listener.newConnectionHandler = self.didAcceptNetwork(connection:)
        listener.serviceRegistrationUpdateHandler = self.didUpdateServiceRegistration(change:)
    }

    private func didUpdateState(to newState: NWListener.State) {
        switch newState {
        case .ready:
            os_log("listener is ready", log: .obscuri, type: .info)
        case .failed(let error):
            // If the listener fails, re-start.
            if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                os_log("listener failed with error: %@, restarting", log: .obscuri, type: .error, error.localizedDescription)
                self.stop()
                self.start()
            } else {
                os_log("listener failed with error: %@, stopping", log: .obscuri, type: .error, error.localizedDescription)
                self.stop()
            }
        case .cancelled:
            os_log("listener cancelled", log: .obscuri, type: .info)
        default:
            break
        }
    }

    private func didAcceptNetwork(connection: NWConnection) {
        os_log("listener received new connection: %@", log: .obscuri, type: .info, connection.debugDescription)
        self.connectionManager.add(connection: connection)
    }

    private func didUpdateServiceRegistration(change: NWListener.ServiceRegistrationChange) {
        switch change {
        case .add(let endpoint):
            os_log("listener added endpoint: %@", log: .obscuri, type: .info, endpoint.debugDescription)
        case .remove(let endpoint):
            os_log("listener removed endpoint: %@", log: .obscuri, type: .info, endpoint.debugDescription)
        @unknown default:
            os_log("listener received unknown update: %@", log: .obscuri, type: .error, String(describing: change))
        }
    }

    fileprivate static func getTLSParameters(allowInsecure: Bool, queue: DispatchQueue) -> NWParameters {
        NWParameters.tcp
//        let options = NWProtocolTLS.Options()
//
//        sec_protocol_options_set_verify_block(options.securityProtocolOptions, { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
//            let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
//            var error: CFError?
//            if SecTrustEvaluateWithError(trust, &error) {
//                sec_protocol_verify_complete(true)
//            } else {
//                if allowInsecure {
//                    sec_protocol_verify_complete(true)
//                } else {
//                    sec_protocol_verify_complete(false)
//                }
//            }
//        }, queue)
//
//        return NWParameters(tls: options)
    }

    public func start() {
        os_log("starting server", log: .obscuri, type: .info)
        listener.start(queue: .obscuriQueue)
    }

    public func send<T: Codable>(_ object: T) throws {
        if connectionManager.connectionsById.isEmpty {
            os_log("no open connections found, not sending data", log: .obscuri, type: .debug)
            return
        }
        os_log("sending object %@", log: .obscuri, type: .info, String(describing: object))
        let payloadData = try JSONEncoder().encode(object)
        let packet = JSONOverTCPPacket(data: payloadData)
        let data = try packet.encode()
        for connection in connectionManager.connectionsById.values {
            connection.networkConnection.send(content: data, completion: .contentProcessed({ error in
                if let error = error {
                    os_log("writing data to connection %@ failed, reason: %@", log: .obscuri, type: .debug, connection.id, error.localizedDescription)
                } else {
                    os_log("writing data to connection %@ successful", log: .obscuri, type: .debug, connection.id)
                }
            }))
        }
    }

    public func stop() {
        listener.cancel()
    }

    // MARK: - Configuration

    var txtRecordData: Data {
        let txtRecord = [
            "id": serviceId, // identifier
            "c#": "1", // version
            "sf": "1", // discoverable
            "ff": "0", // mfi compliant
            "md": serviceName, // name
            "peerID": "123",
        ]
        return NetService.data(fromTXTRecord: txtRecord.mapValues {
            $0.data(using: .utf8)!
        })
    }
}

// MARK: - ConnectionManagerDelegate

extension ObscuriServer: ConnectionManagerDelegate {

    func connectionManager(_ connectionManager: ConnectionManager, didAddConnection connection: Connection) {
        delegate?.obscuriServerDidAddConnection(self)
    }

    func connectionManager(_ connectionManager: ConnectionManager, didCloseConnection connection: Connection) {
        delegate?.obscuriServerDidCloseConnection(self)
    }
}

extension DispatchQueue {
    static let obscuriQueue = DispatchQueue(label: "com.techprimate.Obscuri.Server")
}
