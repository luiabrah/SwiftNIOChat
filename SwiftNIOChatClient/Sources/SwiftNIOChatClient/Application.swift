//
//  Application.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Logging
import Foundation

@main
struct Application {
    static func main() async throws {
        let logger = Logger(label: "com.abraham.swiftniochat.client")
        let defaultHost = "0.0.0.0"
        let defaultPort = 3000
    
        let portArgument = CommandLine.arguments.dropFirst().first
        let port = portArgument.flatMap(Int.init) ?? defaultPort
        
        let client = ChatClient(logger: logger)
        
        do {
            try await client.run(host: defaultHost, port: port)
        } catch {
            logger.info("Caught error \(error)")
            try await client.shutdown()
        }
    }
}
