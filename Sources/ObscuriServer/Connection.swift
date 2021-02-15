import Foundation
import Network
class Connection: Identifiable {

    let id: String
    let networkConnection: NWConnection
//    let inputStream: InputStream
//    let outputStream: OutputStream

    public init(id: String = UUID().uuidString, networkConnection: NWConnection) {
        self.id = id
        self.networkConnection = networkConnection
    }
}

class SecureConnection: Connection {
    
}
