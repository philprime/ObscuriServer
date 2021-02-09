import Foundation
import os.log

@available(OSX 10.12, *)
class ServiceDelegate: NSObject, NetServiceDelegate {

    // MARK: - Services

    private let logger = OSLog(subsystem: LoggingConfig.identifier, category: String(describing: ServiceDelegate.self))

    let manager: ConnectionManager

    // MARK: - Properties

    private let serviceId: String
    private let serviceName: String

    // MARK: - Initializer

    init(serviceId: String, serviceName: String, manager: ConnectionManager) {
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.manager = manager
    }

    // MARK: - NetServiceDelegate

    func netServiceWillPublish(_ sender: NetService) {
        os_log("will publish net service %@ with serviceId: %@ and serviceName: %@", log: logger, type: .debug, sender, serviceId, serviceName)
    }

    func netServiceDidPublish(_ sender: NetService) {
        os_log("did publish net service %@", log: logger, type: .debug, sender)
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        os_log("did not publish sender %@, error: %@", log: logger, type: .error, sender, errorDict)
    }

    func netServiceDidStop(_ sender: NetService) {
        os_log("net service did stop %@", log: logger, type: .info, sender)
    }

    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        let connection = Connection(outputStream: outputStream)
        os_log("opening connection with id %@", log: logger, type: .debug, connection.id)
        outputStream.open()
        manager.add(connection: connection)
    }
}
