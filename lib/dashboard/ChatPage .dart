import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String peerId;
  final String peerName;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;

    // Mark messages as read initially
    _updateLastRead();

    // Listen for new messages to update lastRead automatically
    _dbRef.child('chats/${widget.chatId}/messages').onChildAdded.listen((event) {
      _updateLastRead();
    });
  }

  void _updateLastRead() {
    if (currentUser == null) return;
    _dbRef
        .child('chats/${widget.chatId}/lastRead/${currentUser!.uid}')
        .set(ServerValue.timestamp);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final message = {
      'senderId': currentUser!.uid,
      'text': text,
      'timestamp': ServerValue.timestamp,
    };

    await _dbRef.child('chats/${widget.chatId}/messages').push().set(message);
    _messageController.clear();
    _updateLastRead();
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.peerName,
          style: const TextStyle(
            color: Colors.white,
            letterSpacing: 2,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _dbRef
                  .child('chats/${widget.chatId}/messages')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No messages yet"));
                }

                final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final messages = data.entries.toList()
                  ..sort((a, b) => (a.value['timestamp'] ?? 0)
                      .compareTo(b.value['timestamp'] ?? 0));

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = Map<String, dynamic>.from(messages[i].value);
                    final isMe = msg['senderId'] == uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color.fromARGB(255, 233, 82, 82) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 135, 9, 13)),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to generate unique chatId for each donor-recipient pair
String generateChatId(String uid1, String uid2) {
  return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
}
