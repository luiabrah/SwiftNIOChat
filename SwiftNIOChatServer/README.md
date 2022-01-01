# SwiftNIOChatServer

The goal with this project is to become more familiar with SwiftNIO by building a chat application. This package contains the TCP server that accepts TCP connections and commands from clients to create rooms, join rooms and send messages to other users in the rooms.

## Getting Started
After pulling the package in, the server can be started up by:

```bash
swift run # runs on default port of 3000
swift run SwiftNIOChatServer 5050 # specifies a particular port
```

## Commands the server accepts
* `/createRoom <room_name>` - creates a chat room with name `<room_name>`
* `/joinRoom <room_name>` - attemps to join the chat room named `<room_name>`. If it does not exist, the server will respond with an error message
* `/exitRoom` - exits the current room the user is registered in
* Messages are accepted by just typing into the terminal after the user has joined a chat room
