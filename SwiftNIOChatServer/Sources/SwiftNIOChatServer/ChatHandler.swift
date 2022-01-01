//
//  ChatHandler.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Foundation
import NIOCore
import NIOPosix
import Logging

final class ChatHandler: ChannelInboundHandler {
    typealias InboundIn = ServerMessage
    typealias OutboundOut = ByteBuffer
    
    private let chatRoom: ChatRoom
    private let logger: Logger
    
    init(logger: Logger) {
        self.chatRoom = ChatRoom(logger: logger)
        self.logger = logger
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        let userId = getUserId(from: context)
        let user = User(id: userId, channel: context.channel)
        Task {
            await chatRoom.addActiveUser(user)
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        let userId = getUserId(from: context)
        logger.info("Channel on remote address \(userId) disconnected")
        
        handleExitRoom(context: context)
        
        Task {
            do {
                try await chatRoom.userDisconnected(userId: userId)
            } catch let error as ChatRoom.ChatRoomError {
                writeError(error.errorMessage, context: context)
            }
            
            context.eventLoop.execute {
                context.close(promise: nil)
            }
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = unwrapInboundIn(data)
        switch message {
            case .joinRoom(let roomId): handleJoinRoom(roomId, context: context)
            case .createRoom(let roomId): handleCreateRoom(roomId, context: context)
            case .exitRoom: handleExitRoom(context: context)
            case .broadcast(let message): handleBroadcast(message, context: context)
            case .invalidCommand(let command): writeError("Invalid command \(command)", context: context)
        }
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        logger.info("Channel read complete")
        context.flush()
    }
    
    private func writeError(_ message: String, context: ChannelHandlerContext) {
        writeToClient("\u{1B}[91m\(message)\u{1B}[0m", context: context)
    }
    
    private func writeSuccess(_ message: String, context: ChannelHandlerContext) {
        writeToClient("\u{1B}[92m\(message)\u{1B}[0m", context: context)
    }
    
    private func writeToClient(_ message: String, context: ChannelHandlerContext) {
        logger.info("Sending to client: \(message)")
        context.eventLoop.execute {
            let buffer = context.channel.allocator.buffer(string: message)
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        }
    }
    
    private func handleJoinRoom(_ roomId: RoomId, context: ChannelHandlerContext)  {
        let userId = getUserId(from: context)
        Task {
            do {
                try await chatRoom.joinRoom(userId: userId, roomId: roomId)
                let room = try await chatRoom.room(forId: roomId)
                broadcast(message: "\(userId) has joined room \(roomId)", toRoom: room, from: nil, context: context)
            } catch let error as ChatRoom.ChatRoomError {
                writeError(error.errorMessage, context: context)
            }
        }
    }
    
    private func handleCreateRoom(_ roomId: RoomId, context: ChannelHandlerContext)  {
        Task {
            do {
                try await chatRoom.createRoom(roomId)
                writeSuccess("Successfully created room \(roomId)", context: context)
            } catch let error as ChatRoom.ChatRoomError {
                writeError(error.errorMessage, context: context)
            }
        }
    }

    private func handleExitRoom(context: ChannelHandlerContext) {
        let userId = getUserId(from: context)
        
        Task {
            do {
                let roomId = try await chatRoom.exitRoom(userId: userId)
                if let roomId = roomId {
                    let room = try await chatRoom.room(forId: roomId)
                    broadcast(message: "\(userId) has left room \(roomId)", toRoom: room, from: nil, context: context)
                    writeSuccess("Left room \(roomId)", context: context)
                } else {
                    writeError("Currently not in any room", context: context)
                }
                
            } catch let error as ChatRoom.ChatRoomError {
                writeError(error.errorMessage, context: context)
            }
        }
    }
   
    private func handleBroadcast(_ message: String, context: ChannelHandlerContext) {
        let userId = getUserId(from: context)
        Task {
            do {
                let room = try await chatRoom.room(forUser: userId)
                broadcast(message: message, toRoom: room, from: userId, context: context)
            } catch let error as ChatRoom.ChatRoomError {
                writeError(error.errorMessage, context: context)
            }
        }
    }
    
    private func broadcast(message: String, toRoom room: Room, from userId: UserId?, context: ChannelHandlerContext) {
        context.eventLoop.execute {
            room.participants.forEach { user in
                guard user.id != userId else {
                    return
                }
                var messageToSend: String
                if let userId = userId {
                    messageToSend = "<\(userId)> \(message)"
                } else {
                    messageToSend = "\u{1B}[94m\(message)\u{1B}[0m"
                }
                self.logger.info("Sending \(messageToSend) to user \(user.id)")
                let outboundByteBuffer = user.channel.allocator.buffer(string: messageToSend)
                user.channel.writeAndFlush(self.wrapOutboundOut(outboundByteBuffer), promise: nil)
            }
        }
    }
    
    private func getUserId(from context: ChannelHandlerContext) -> UserId {
        guard let remoteAddress = context.remoteAddress,
              let ipAddress = remoteAddress.ipAddress,
              let port = remoteAddress.port else {
            fatalError("Active connection does not have a valid address. Not a valid state.")
            
        }
        
        return "\(ipAddress):\(port)"
    }
}

