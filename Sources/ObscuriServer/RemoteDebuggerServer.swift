import Foundation
import os.log
import JSONOverTCP

@available(OSX 10.12, *)
public class ObscuriServer {

    // MARK: - Services

    private let connectionManager = ConnectionManager()
    private let logger = OSLog(subsystem: LoggingConfig.identifier, category: String(describing: ObscuriServer.self))

    // MARK: - Properties

    private let serviceId: String
    private let serviceName: String
    private let service: NetService
    private lazy var serviceDelegate: ServiceDelegate = {
        return ServiceDelegate(serviceId: serviceId, serviceName: serviceName, manager: connectionManager)
    }()

    // MARK: - Intializer

    public init(serviceId: String = UUID().uuidString, serviceName: String) {
        self.serviceId = serviceId
        self.serviceName = serviceName
        service = NetService(domain: "local", type: "_Obscuri._tcp", name: serviceName, port: 0)
        service.delegate = serviceDelegate

        let txtRecord = [
            "id": serviceId, // identifier
            "c#": "1", // version
            "sf": "1", // discoverable
            "ff": "0", // mfi compliant
            "md": serviceName, // name
        ]
        let data = NetService.data(fromTXTRecord: txtRecord.mapValues { $0.data(using: .utf8)! })
        guard data.count <= 0xFFFF else {
            fatalError("TXT Record can't be larger than 65535 bytes")
        }
        os_log("setting TXT record: %@", log: logger, type: .debug, txtRecord)
        precondition(service.setTXTRecord(data))
    }

    public func start() {
        os_log("starting server", log: logger, type: .info)
        service.schedule(in: .current, forMode: .default)
        service.publish(options: .listenForConnections)
    }

    public func send<T: Codable>(_ object: T) throws {
        if connectionManager.connections.isEmpty {
            os_log("no open connections found, not sending data", log: logger, type: .debug)
            return
        }
        os_log("sending object %@", log: logger, type: .info, String(describing: object))
        let payloadData = try JSONEncoder().encode(object)
        let packet = JSONOverTCPPacket(data: payloadData)
        let data = try packet.encode()
        data.withUnsafeBytes({ (rawBufferPointer: UnsafeRawBufferPointer) in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            for connection in connectionManager.connections {
                if connection.outputStream.hasSpaceAvailable {
                    os_log("writing %i bytes to connection %@", log: logger, type: .debug, data.count, connection.id)
                    connection.outputStream.write(bufferPointer.baseAddress!, maxLength: data.count)
                } else {
                    connectionManager.close(connection: connection)
                }
            }
        })
    }

    public func stop() {
        service.stop()
    }
}
