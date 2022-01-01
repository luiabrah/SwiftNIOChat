# SwiftNIOChatClient

The goal with this project is to become more familiar with SwiftNIO by building a chat application. This package contains the chat client that attempts to connect to the TCP server on a particular port. The client represents one user in a chat room.

## Getting Started
After pulling the package in, the client can be started up by:

```bash
swift run # connects to default port of 3000
swift run SwiftNIOChatClient 5050 # specifies a particular port
```

## Commands
* `/createRoom <room_name>` - creates a chat room with name `<room_name>`
* `/joinRoom <room_name>` - attemps to join the chat room named `<room_name>`. If it does not exist, the server will respond with an error message
* `/exitRoom` - exits the current room the user is registered in
* To send a message to the chat room, simply type anything into your terminal and it will be broadcasted to all users in the chat room. If you are not in a chat room, the server will respond with an error message.