//
//  InitialMessageHandler .swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Foundation
import Logging
import NIOCore

final class InitialMessageHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func channelActive(context: ChannelHandlerContext) {
        guard let userIpAddress = context.remoteAddress?.ipAddress else {
            logger.error("Active connection does not have an IP address.")
            return
        }
        
        logger.info("InitialHandshakeHandler - Channel active on remote address \(userIpAddress)")
        
        let welcomeMessage = """
        
            Welcome to Athena! Here are the commands you can use:
            * /joinRoom <roomName>
            * /createRoom <roomName>
            * /exitRoom
        
            Once you're in a room, type anything to broadcast a message to all users in the room.
        
        """
        
        let buffer = context.channel.allocator.buffer(string: welcomeMessage)
        context.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
        
        context.channel.pipeline.removeHandler(self).whenComplete { result in
            switch result {
                case .success:
                    self.logger.info("Successfully removed InitialHandshakeHandler")
                case .failure(let error):
                    self.logger.error("Error removing InitialHandshakeHandler caused by: \(error)")
            }
        }
    }
}

