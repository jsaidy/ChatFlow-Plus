# ChatFlow+

## Distributed Fault-Tolerant Real-Time Chat System

**Author:** Jerreh Saidy  
**Program:** MSc Artificial Intelligence and Data Engineering  
**University:** University of Pisa

---

## Overview

ChatFlow+ is a distributed real-time chat system developed using Erlang/OTP and Spring Boot. The project demonstrates fundamental distributed systems concepts including actor-based concurrency, distributed message passing, fault tolerance, node monitoring, distributed persistence, and RESTful communication.

The system consists of a Spring Boot gateway that communicates with an Erlang-based distributed backend running across multiple nodes.

---

## Features

- Dynamic node discovery
- Fault-tolerant message delivery
- User session management
- Distributed message persistence using Mnesia
- REST API integration
- Node monitoring and failure detection
- Chat history storage
- Multi-node communication

---

## System Architecture

```text
┌─────────────────────────────────────────┐
│              CLIENT LAYER               │
│                                         │
│   cURL Requests      Browser Clients    │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         Spring Boot REST API            │
│               Port 8081                 │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         DISTRIBUTED BACKEND             │
│                                         │
│  ┌──────────────┐    ┌──────────────┐   │
│  │   Node 1     │    │   Node 2     │   │
│  │ Dispatcher   │    │ Dispatcher   │   │
│  │   Mnesia     │◄──►│   Mnesia     │   │
│  └──────────────┘    └──────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

## Technologies Used

| Technology | Purpose |
|------------|---------|
| Erlang/OTP | Distributed backend |
| Mnesia | Distributed database |
| Spring Boot | REST API gateway |
| Java 17 | Application runtime |
| Maven | Build automation |

---

## Project Structure

```text
ChatFlow-Plus/
├── README.md
├── LICENSE
├── .gitignore
│
├── erlang_backend/
│   └── src/
│       ├── chat_dispatcher.erl
│       ├── chat_user.erl
│       └── node_monitor.erl
│
├── spring_gateway/
│   ├── src/
│   ├── pom.xml
│   └── application.yml
│
├── docs/
│
└── scripts/
```

---

## Core Components

### Chat Dispatcher

Responsible for:

- Routing messages between users
- Managing active user registrations
- Persisting chat history
- Coordinating communication between nodes

### Chat User

Represents an active user process that:

- Receives messages
- Sends acknowledgements
- Maintains active sessions

### Node Monitor

Responsible for:

- Detecting node joins
- Detecting node failures
- Monitoring cluster health

### Mnesia Database

Stores:

- User information
- Chat history
- Message metadata
- Delivery status

### Spring Boot REST API

Provides external access to the distributed chat system.

| Method | Endpoint | Description |
|----------|----------|----------|
| POST | `/api/chat/send` | Send a message |
| GET | `/api/chat/health` | Health check |

---

## Prerequisites

- Erlang/OTP 28+
- Java 17+
- Maven 3.9+

---

## Running the Project

### Terminal 1 – Start Node 1

```bash
cd erlang_backend/src
erl -sname node1 -setcookie same_cookie
```

Compile and start services:

```erlang
c(chat_dispatcher).
c(chat_user).
c(node_monitor).

chat_dispatcher:start().
chat_user:login("Alice").
node_monitor:start().
```

### Terminal 2 – Start Node 2

```bash
cd erlang_backend/src
erl -sname node2 -setcookie same_cookie
```

Compile and start services:

```erlang
c(chat_dispatcher).
```
Connect nodes:

```erlang
```

Replace `HOSTNAME` with your machine hostname.


```bash
cd spring_gateway
```

### Terminal 4 – Send a Test Message
```bash
curl -X POST http://localhost:8081/api/chat/send \
-d '{"from":"Alice","to":"Bob","content":"Hello!"}'
```

---


### Send a Message

```erlang
chat_dispatcher:send_message(
    "Bob",
    "Hello from ChatFlow+!"
).

### View Chat History


### List Online Users

```erlang
chat_dispatcher:list_users().
```


## Distributed Systems Concepts Demonstrated
- Actor Model
- Fault Tolerance
- Distributed Persistence
- Process Supervision
- Node Monitoring
- Distributed Communication
- Service Coordination

---

## Reliability Features

| Feature | Description |
|----------|-------------|
| Retry Mechanism | Retransmits failed messages |
| Node Monitoring | Detects joins and failures |
| Persistence | Messages stored in Mnesia |
| User Recovery | Sessions can be reassigned |
| Fault Detection | Identifies unavailable nodes |

---

## Requirements Achieved

| Requirement | Status |
|-------------|--------|
| Dynamic node management | ✅ |
| Message migration | ✅ |
| Reliability mechanisms | ✅ |
| Synchronization analysis | ✅ |
| Client interaction | ✅ |

---

## Future Improvements

- Exactly-once message delivery
- Automatic split-brain recovery
- WebSocket support
- User authentication
- Docker deployment
- Kubernetes orchestration

---

## License

This project is licensed under the MIT License.

See the LICENSE file for details.

---

## Author

**Jerreh Saidy**

MSc Artificial Intelligence and Data Engineering  
University of Pisa- Message Passing

