//
//  ChatMessageDecoder.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Foundation
import NIOCore
import Logging

enum ServerMessage {
    private static let commandCharacter = "/"
    private static let whiteSpaceCharacter: Character = " "
    private static let joinRoomCommand = "/joinRoom"
    private static let createRoomCommand = "/createRoom"
    private static let exitRoomCommand = "/exitRoom"
    
    case joinRoom(RoomId)
    case createRoom(RoomId)
    case exitRoom
    case broadcast(String)
    case invalidCommand(String)
    
    init(message: String) {
        if message.hasPrefix(Self.commandCharacter) {
            self = Self.parseCommand(message: message)
        } else {
            self = .broadcast(message)
        }
    }
    
    private static func parseCommand(message: String) -> ServerMessage {
        let splitMessage = message.split(separator: Self.whiteSpaceCharacter,
                                                      maxSplits: 1,
                                                      omittingEmptySubsequences: true)
        
        let commandString = String(splitMessage[0])
        
        switch commandString {
            case Self.joinRoomCommand:
                guard splitMessage.count == 2 else {
                    return .invalidCommand(message)
                }
                let roomId = String(splitMessage[1])
                return .joinRoom(roomId)
            case Self.createRoomCommand:
                guard splitMessage.count == 2 else {
                    return .invalidCommand(message)
                }
                let roomId = String(splitMessage[1])
                return .createRoom(roomId)
            case Self.exitRoomCommand:
                return .exitRoom
            default:
                return .invalidCommand(message)
        }
        
    }
}

final class ChatMessageDecoder: ByteToMessageDecoder {
    typealias InboundOut = ServerMessage
    
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard let bytes = buffer.readBytes(length: buffer.readableBytes) else {
            logger.info("ChatMessageDecoder requesting more data")
            return .needMoreData
        }
        
        guard let incomingMessage = String(bytes: bytes, encoding: .utf8) else {
            logger.info("Unable to convert bytes to string")
            return .needMoreData
        }
        
        if incomingMessage == "" {
            return .needMoreData
        }
        
        let serverMessage = ServerMessage(message: incomingMessage)

        context.fireChannelRead(self.wrapInboundOut(serverMessage))
        
        return .continue
    }
}

