# ChatFlow+ - Complete System Test Guide

**Author:** Jerreh Saidy  
**Date:** June 2026

This document contains step-by-step instructions to test the entire ChatFlow+ distributed chat system from a clean state.

---

## Prerequisites

- Erlang/OTP 28+
- Java 17+
- Maven 3.9+
- curl (for REST API testing)

---

## Test 1: Clean Start (Remove Old Data)

### Step 1: Clean Mnesia Data

```bash
cd ~/Desktop/ReliableTasksystem/erlang_backend/src
rm -rf Mnesia.*
rm *.beam
```

✅ **Expected:** No error messages. Files are removed.

---

## Test 2: Start Node 1 (Alice)

### Step 2: Start Node 1

**Terminal 1:**

```bash
cd ~/Desktop/ReliableTasksystem/erlang_backend/src
erl -sname node1 -setcookie same_cookie
```

**Copy and paste these commands ONE BY ONE:**

```erlang
mnesia:stop().
mnesia:delete_schema([node()]).
mnesia:start().
mnesia:create_schema([node()]).
mnesia:start().
c(chat_dispatcher).
c(chat_user).
c(node_monitor).
chat_dispatcher:start().
chat_user:login("Alice").
node_monitor:start().
```

✅ **Expected Output:**
```
Chat database ready
Chat system started on node1@jsaidy
User Alice logged in on node1@jsaidy
User Alice registered on node1@jsaidy
Node monitor started on node1@jsaidy
```

**Leave this terminal open.**

---

## Test 3: Start Node 2 (Bob)

### Step 3: Start Node 2

**Terminal 2 (new terminal):**

```bash
cd ~/Desktop/ReliableTasksystem/erlang_backend/src
erl -sname node2 -setcookie same_cookie
```

**Copy and paste these commands ONE BY ONE:**

```erlang
mnesia:stop().
mnesia:delete_schema([node()]).
mnesia:start().
mnesia:create_schema([node()]).
mnesia:start().
mnesia:change_config(extra_db_nodes, ['node1@jsaidy']).
mnesia:wait_for_tables([message, user], 10000).
c(chat_dispatcher).
c(chat_user).
c(node_monitor).
chat_dispatcher:start().
chat_user:login("Bob").
node_monitor:start().
net_kernel:connect_node('node1@jsaidy').
```

✅ **Expected Output:**
```
Chat database ready
Chat system started on node2@jsaidy
User Bob logged in on node2@jsaidy
User Bob registered on node2@jsaidy
Node monitor started on node2@jsaidy
*** SERVER NODE JOINED: node2@jsaidy ***
```

**Leave this terminal open.**

---

## Test 4: Verify User Registry (Replication Test)

### Step 4: Check users on Node 1

**In Terminal 1:**

```erlang
chat_dispatcher:list_users().
```

✅ **Expected Output:**
```
=== Online Users (2) ===
  Alice on node1@jsaidy
  Bob on node2@jsaidy
ok
```

### Step 5: Check users on Node 2

**In Terminal 2:**

```erlang
chat_dispatcher:list_users().
```

✅ **Expected Output:**
```
=== Online Users (2) ===
  Alice on node1@jsaidy
  Bob on node2@jsaidy
ok
```

**✅ TEST PASSED:** Both nodes show all users. Mnesia replication is working.

---

## Test 5: Send Message (Alice → Bob)

### Step 6: Send message from Alice

**In Terminal 1:**

```erlang
chat_dispatcher:send_message("Alice", "Bob", "Hello Bob! This is a test message.").
```

✅ **Expected Output in Terminal 1:**
```
Message 1 from Alice to Bob
Message 1 sent to Bob on node2@jsaidy
```

✅ **Expected Output in Terminal 2:**
```
*** NEW MESSAGE for Bob from Alice: Hello Bob! This is a test message. ***
Message 1 delivered
```

**✅ TEST PASSED:** Message delivered from Alice to Bob.

---

## Test 6: Send Message (Bob → Alice)

### Step 7: Send reply from Bob

**In Terminal 2:**

```erlang
chat_dispatcher:send_message("Bob", "Alice", "Hi Alice! Got your message.").
```

✅ **Expected Output in Terminal 2:**
```
Message 2 from Bob to Alice
Message 2 sent to Alice on node1@jsaidy
```

✅ **Expected Output in Terminal 1:**
```
*** NEW MESSAGE for Alice from Bob: Hi Alice! Got your message. ***
Message 2 delivered
```

**✅ TEST PASSED:** Reply delivered from Bob to Alice.

---

## Test 7: Verify Chat History

### Step 8: Check chat history
=== Chat History (2 messages) ===
  Message 2: Bob -> Alice: Hi Alice! Got your message.
```

**✅ TEST PASSED:** Chat history is persisted and shows both messages.

---

## Test 8: Node Failure Detection

### Step 9: Kill Node 2


✅ **Expected Output in Terminal 1:**
```
*** SERVER NODE LEFT: node2@jsaidy ***
*** NODE LEFT: node2@jsaidy ***
```

**✅ TEST PASSED:** Node failure detected successfully.

---

## Test 9: Send Message After Node Failure

### Step 10: Send message after node is down

**In Terminal 1:**

```erlang
chat_dispatcher:send_message("Alice", "Bob", "Bob, are you still there?").
```

✅ **Expected Output:**
```
Message 3 from Alice to Bob
User Bob not online
```

**✅ TEST PASSED:** System correctly reports user as offline.

---

## Test 10: Node Rejoin

### Step 11: Restart Node 2

**Terminal 2 (new terminal):**

```bash
cd ~/Desktop/ReliableTasksystem/erlang_backend/src
erl -sname node2 -setcookie same_cookie
```

```erlang
mnesia:start().
mnesia:change_config(extra_db_nodes, ['node1@jsaidy']).
mnesia:wait_for_tables([message, user], 10000).
c(chat_dispatcher).
c(chat_user).
c(node_monitor).
chat_dispatcher:start().
chat_user:login("Bob").
node_monitor:start().
net_kernel:connect_node('node1@jsaidy').
```

✅ **Expected Output in Terminal 1:**
```
*** SERVER NODE JOINED: node2@jsaidy ***
*** NODE JOINED: node2@jsaidy ***
```

**✅ TEST PASSED:** Node rejoined successfully.

---

## Test 11: Verify Users After Rejoin

### Step 12: Check users after rejoin

**In Terminal 1:**

```erlang
chat_dispatcher:list_users().
```

✅ **Expected Output:**
```
=== Online Users (2) ===
  Alice on node1@jsaidy
  Bob on node2@jsaidy
ok
```

**✅ TEST PASSED:** User registry restored after node rejoin.

---

## Test 12: Send Message After Rejoin

### Step 13: Send message after rejoin

**In Terminal 1:**

```erlang
chat_dispatcher:send_message("Alice", "Bob", "Welcome back Bob!").
```

✅ **Expected Output in Terminal 1:**
```
Message 4 from Alice to Bob
Message 4 sent to Bob on node2@jsaidy
```

✅ **Expected Output in Terminal 2:**
```
*** NEW MESSAGE for Bob from Alice: Welcome back Bob! ***
Message 4 delivered
```

**✅ TEST PASSED:** Messages delivered after node rejoin.

---

## Test 13: Final Chat History Check

### Step 14: Check final chat history

**In either terminal:**

```erlang
chat_dispatcher:chat_history().
```

✅ **Expected Output:**
```
=== Chat History (4 messages) ===
  Message 1: Alice -> Bob: Hello Bob! This is a test message.
  Message 2: Bob -> Alice: Hi Alice! Got your message.
  Message 3: Alice -> Bob: Bob, are you still there?
  Message 4: Alice -> Bob: Welcome back Bob!
ok
```

**✅ TEST PASSED:** All messages persisted across node failure and restart.

---

## Test 14: REST API Test

### Step 15: Start Spring Boot

**Terminal 3 (new terminal):**

```bash
cd ~/Desktop/ReliableTasksystem/spring_gateway
mvn spring-boot:run
```

✅ **Expected Output:**
```
Tomcat started on port(s): 8081 (http)
Task Gateway started on http://localhost:8080
```

**Leave this terminal open.**

### Step 16: Test Health Endpoint

**Terminal 4 (new terminal):**

```bash
curl http://localhost:8081/api/chat/health
```

✅ **Expected Output:**
```json
{"status":"alive"}
```

**✅ TEST PASSED:** Health endpoint working.

### Step 17: Test Send Endpoint

**Terminal 4:**

```bash
curl -X POST http://localhost:8081/api/chat/send \
  -H "Content-Type: application/json" \
  -d '{"from":"Alice","to":"Bob","content":"Hello via REST API!"}'
```

✅ **Expected Output:**
```json
{"messageId":...,"from":"Alice","to":"Bob","content":"Hello via REST API!","status":"sent","timestamp":"..."}
```

**✅ TEST PASSED:** REST API sends messages successfully.

---

## Test 15: Chat History After REST API

### Step 18: Check chat history

**In either Terminal 1 or 2:**

```erlang
chat_dispatcher:chat_history().
```

✅ **Expected Output:**
```
=== Chat History (5 messages) ===
  Message 1: Alice -> Bob: Hello Bob! This is a test message.
  Message 2: Bob -> Alice: Hi Alice! Got your message.
  Message 3: Alice -> Bob: Bob, are you still there?
  Message 4: Alice -> Bob: Welcome back Bob!
  Message 5: Alice -> Bob: Hello via REST API!
ok
```

**✅ TEST PASSED:** REST API messages persisted in chat history.

---

## 📊 Test Results Summary

| Test | Description | Status |
|------|-------------|--------|
| 1 | Clean start | |
| 2 | Node 1 starts | |
| 3 | Node 2 starts and connects | |
| 4 | User registry replication | |
| 5 | Alice → Bob message | |
| 6 | Bob → Alice message | |
| 7 | Chat history shows 2 messages | |
| 8 | Node failure detection | |
| 9 | Send after node failure | |
| 10 | Node rejoin | |
| 11 | Users after rejoin | |
| 12 | Message after rejoin | |
| 13 | Final chat history shows 4 messages | |
| 14 | REST API health endpoint | |
| 15 | REST API send endpoint | |
| 16 | Chat history after REST API | |

---

## 🎯 All Tests Passed!

**Congratulations! Your ChatFlow+ system is 100% functional and ready for submission!**

### System Capabilities Verified:
- ✅ Dynamic node join/leave detection
- ✅ Cross-node user registry replication
- ✅ Real-time message delivery
- ✅ Chat history persistence
- ✅ Node failure recovery
- ✅ REST API client interaction
- ✅ Mnesia distributed database

---

**Tested by:** Jerreh Saidy  
**Date:** June 2026**In Terminal 2:** Press `Ctrl+C` twice to kill Node 2.
ok
  Message 1: Alice -> Bob: Hello Bob! This is a test message.
```

**In either terminal:**
```erlang
chat_dispatcher:chat_history().

✅ **Expected Output:**
```

