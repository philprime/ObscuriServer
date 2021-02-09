import Foundation

class Connection: Identifiable {

    let id: String
    let outputStream: OutputStream

    public init(id: String = UUID().uuidString, outputStream: OutputStream) {
        self.id = id
        self.outputStream = outputStream
    }
}
