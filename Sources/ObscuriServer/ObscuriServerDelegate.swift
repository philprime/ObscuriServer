public protocol ObscuriServerDelegate: class {

    func obscuriServerDidAddConnection(_ obscuriServer: ObscuriServer)
    func obscuriServerDidCloseConnection(_ obscuriServer: ObscuriServer)
}

extension ObscuriServerDelegate {

    public func obscuriServerDidAddConnection(_ obscuriServer: ObscuriServer) {}
    public func obscuriServerDidCloseConnection(_ obscuriServer: ObscuriServer) {}

}
