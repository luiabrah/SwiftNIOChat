//
//  ChatRoom.swift
//  
//
//  Created by Luis Abraham on 2022-01-01.
//

import Foundation
import Logging
import NIOCore

typealias RoomId = String
typealias UserId = String

struct User: Hashable {
    let id: UserId
    let channel: Channel
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Room {
    let id: RoomId
    var participants: Users
}

typealias Users = Set<User>
typealias Rooms = [RoomId: Room]
typealias ActiveUsers = [UserId: User]
typealias UsersToRooms = [UserId: RoomId]

actor ChatRoom {
    
    private var rooms: Rooms
    private var activeUsers: ActiveUsers
    private var usersToRooms: UsersToRooms
    private let logger: Logger
    
    init(logger: Logger) {
        self.rooms = [:]
        self.activeUsers = [:]
        self.usersToRooms = [:]
        self.logger = logger
    }
    
    enum ChatRoomError: Error {
        case roomAlreadyExists(message: String)
        case roomNotFound(message: String)
        case userAlreadyInRoom(message: String)
        case userNotFound(message: String)
        case userNotInRoom(message: String)
        
        var errorMessage: String {
            switch self {
                case .roomNotFound(let message),
                        .roomAlreadyExists(message: let message),
                        .userAlreadyInRoom(let message),
                        .userNotFound(let message),
                        .userNotInRoom(let message):
                    return message
            }
        }
    }
    
    func addActiveUser(_ user: User) {
        logger.info("Adding active user \(user.id)")
        activeUsers[user.id] = user
    }
    
    func joinRoom(userId: UserId, roomId: RoomId) throws {
        logger.info("User \(userId) joining room \(roomId)")
        
        let room = try room(forId: roomId)
        let user = try activeUser(forId: userId)
        
        guard !room.participants.contains(user) else {
            let errorMessage = "User \(userId) already in room \(roomId)"
            logger.error("\(errorMessage)")
            throw ChatRoomError.userAlreadyInRoom(message: errorMessage)
        }
        
        // Exit current room if user is already in one
        try exitRoom(userId: userId)
        
        var roomParticipants = room.participants
        roomParticipants.insert(user)
        
        let updatedRoom = Room(id: roomId, participants: roomParticipants)
        rooms[roomId] = updatedRoom
        
        usersToRooms[userId] = roomId
    }
   
    func createRoom(_ roomId: RoomId) throws {
        logger.info("Creating room \(roomId)")
        
        if let existingRoomId = self.rooms[roomId] {
            let errorMessage = "Attempting to create a room that already exists \(existingRoomId)"
            logger.error("\(errorMessage)")
            throw ChatRoomError.roomAlreadyExists(message: errorMessage)
        }
        
        let room = Room(id: roomId, participants: [])
        self.rooms[roomId] = room
        logger.info("Successfully created room \(roomId)")
    }
    
    @discardableResult
    func exitRoom(userId: UserId) throws -> RoomId? {
        logger.info("Removing \(userId) from current room")
        
        guard let currentUserRoomId = usersToRooms[userId] else {
            logger.info("\(userId) not in any rooms")
            return nil
        }
        usersToRooms.removeValue(forKey: userId)
        // Look up room and remove user from participants
        let currentRoom = try room(forId: currentUserRoomId)
        let user = try activeUser(forId: userId)
        var currentRoomParticipants = currentRoom.participants
        currentRoomParticipants.remove(user)
        let updatedRoom = Room(id: currentUserRoomId, participants: currentRoomParticipants)
        rooms[currentUserRoomId] = updatedRoom
        logger.info("Successfully removed \(userId) from room \(currentUserRoomId)")
        
        return currentUserRoomId
    }
    
    func userDisconnected(userId: UserId) throws {
        activeUsers.removeValue(forKey: userId)
        usersToRooms.removeValue(forKey: userId)
    }
    
    func room(forUser userId: UserId) throws -> Room {
        guard let currentRoomId = usersToRooms[userId] else {
            let errorMessage = "User \(userId) is not in any room"
            logger.error("\(errorMessage)")
            throw ChatRoomError.userNotInRoom(message: errorMessage)
        }
        
        return try room(forId: currentRoomId)
    }
    
    func room(forId roomId: RoomId) throws -> Room {
        guard let room = rooms[roomId] else {
            let errorMessage = "Room \(roomId) does not exist"
            logger.error("\(errorMessage)")
            throw ChatRoomError.roomNotFound(message: errorMessage)
        }
        
        return room
    }
    
    private func activeUser(forId userId: UserId) throws -> User {
        guard let user = activeUsers[userId] else {
            let errorMessage = "User \(userId) does not exist"
            logger.error("\(errorMessage)")
            throw ChatRoomError.userNotFound(message: errorMessage)
        }
        
        return user
    }
}
