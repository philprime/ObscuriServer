protocol ConnectionManagerDelegate: class {

    func connectionManager(_ connectionManager: ConnectionManager, didAddConnection connection: Connection)
    func connectionManager(_ connectionManager: ConnectionManager, didCloseConnection connection: Connection)
}

extension ConnectionManagerDelegate {

    public func connectionManager(_ connectionManager: ConnectionManager, didAddConnection connection: Connection) {}
    public func connectionManager(_ connectionManager: ConnectionManager, didCloseConnection connection: Connection) {}
}
