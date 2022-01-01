//
//  Server.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Logging
import NIOCore
import NIOPosix

final class Server {
    // MARK: - Constants
    private static let serverBacklog: Int32 = 256
    private static let maxMessagesPerRead: UInt = 16

    // MARK: - Properties
    private let eventLoopGroup: EventLoopGroup
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }

    private var bootstrap: ServerBootstrap {
        // We want this handler to be shared by all connections
        let chatHandler = ChatHandler(logger: self.logger)
        return ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: Self.serverBacklog)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers([
                    BackPressureHandler(),
                    InitialMessageHandler(logger: self.logger),
                    ByteToMessageHandler(ChatMessageDecoder(logger: self.logger)),
                    chatHandler
                ])
           
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: Self.maxMessagesPerRead)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    func shutdown() async throws {
        logger.info("Shutting down server")
        try await eventLoopGroup.shutdownGracefully()
    }
    
    func run(host: String, port: Int) async throws -> Channel {
        logger.info("Running server on address \(host):\(port)")
        return try await bootstrap.bind(host: host, port: port).get()
    }
}

