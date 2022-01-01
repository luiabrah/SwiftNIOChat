//
//  ChatClient.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Logging
import NIOCore
import NIOPosix

final class ChatClient {
    private let eventLoopGroup: EventLoopGroup
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }
    
    private var bootstrap: ClientBootstrap {
        ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(ServerResponseHandler(logger: self.logger))
            }
    }
    
    func shutdown() async throws {
        logger.info("Client shutdown")
        try await eventLoopGroup.shutdownGracefully()
    }
    
    func run(host: String, port: Int) async throws {
        logger.info("Running client")
        let channel = try await bootstrap.connect(host: host, port: port).get()
        while let input = readLine() {
            logger.debug("Sending \(input) to server")
            let buffer = channel.allocator.buffer(string: input)
            try await channel.writeAndFlush(buffer)
        }
    }
}

