//
//  Application.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Logging

@main
struct Application {
    static func main() async throws {
        let defaultHost = "0.0.0.0"
        let defaultPort = 3000
        
        let portArgument = CommandLine.arguments.dropFirst().first
        let port = portArgument.flatMap(Int.init) ?? defaultPort
        
        let logger = Logger(label: "com.abraham.swiftniochat.server")
        let server = Server(logger: logger)
        do {
            let serverChannel = try await server.run(host: defaultHost, port: port)
            try await serverChannel.closeFuture.get()
        } catch {
            logger.error("Caught error \(error)")
            try await server.shutdown()
        }
    }
}

