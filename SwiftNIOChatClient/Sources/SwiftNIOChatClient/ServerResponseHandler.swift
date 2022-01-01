//
//  ServerResponseHandler.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Foundation
import Logging
import NIOCore

final class ServerResponseHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func channelActive(context: ChannelHandlerContext) {
        guard let remoteAddress = context.remoteAddress?.ipAddress else {
            logger.error("Missing remote address.")
            return
        }
        
        logger.info("Connected to remote address \(remoteAddress)")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var byteBuffer = unwrapInboundIn(data)
        
        guard let incomingData = byteBuffer.readString(length: byteBuffer.readableBytes) else {
            logger.error("Unable to read string from byte buffer")
            return
        }
        
        print(incomingData)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("Caught error \(error)")
        context.close(promise: nil)
    }
}

