import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../ChatPage .dart';

class RecipientChatsPage extends StatefulWidget {
  final User user;

  const RecipientChatsPage({super.key, required this.user});

  @override
  State<RecipientChatsPage> createState() => _RecipientChatsPageState();
}

class _RecipientChatsPageState extends State<RecipientChatsPage> {
  final DatabaseReference _requestsRef = FirebaseDatabase.instance.ref("requests");

  String generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(
            fontSize: 28,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _requestsRef.orderByChild("uid").equalTo(widget.user.uid).onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No accepted chats yet"));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          // Filter accepted requests
          final acceptedRequests = data.entries
              .where((e) {
                final value = Map<String, dynamic>.from(e.value);
                return value['status'] == "accepted";
              })
              .toList();

          if (acceptedRequests.isEmpty) {
            return const Center(child: Text("No accepted chats"));
          }

          // Aggregate unique donors
          final Map<String, Map<String, dynamic>> donorsMap = {};
          for (var e in acceptedRequests) {
            final value = Map<String, dynamic>.from(e.value);
            final donorUid = value['acceptedBy'] ?? '';
            if (donorUid.isNotEmpty) {
              donorsMap[donorUid] = {
                "name": value['acceptedByName'] ?? "Donor",
                "bloodGroup": value['bloodGroup'] ?? "",
              };
            }
          }

          final donorsList = donorsMap.entries.toList();

          return ListView.builder(
            itemCount: donorsList.length,
            itemBuilder: (context, index) {
              final donorUid = donorsList[index].key;
              final donorData = donorsList[index].value;
              final chatId = generateChatId(widget.user.uid, donorUid);

              // Real-time StreamBuilder for the chat node
              return StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('chats/$chatId').onValue,
                builder: (context, chatSnapshot) {
                  int unseenCount = 0;
                  int lastReadTime = 0;

                  if (chatSnapshot.hasData && chatSnapshot.data!.snapshot.value != null) {
                    final chatData = Map<String, dynamic>.from(chatSnapshot.data!.snapshot.value as Map);

                    // Read lastRead timestamp safely
                    final lastReadMap = chatData['lastRead'] as Map<dynamic, dynamic>? ?? {};
                    lastReadTime = lastReadMap[widget.user.uid] is int
                        ? lastReadMap[widget.user.uid]
                        : 0;

                    // Count unseen messages
                    final messagesMap = chatData['messages'] as Map<dynamic, dynamic>? ?? {};
                    messagesMap.forEach((key, msg) {
                      final m = Map<String, dynamic>.from(msg);
                      final senderId = m['senderId'] ?? '';
                      final timestamp = m['timestamp'] ?? 0;

                      if (senderId != widget.user.uid && timestamp > lastReadTime) {
                        unseenCount++;
                      }
                    });
                  }

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(donorData['name']),
                    subtitle: Text("Blood: ${donorData['bloodGroup']}"),
                    trailing: unseenCount > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Text(
                              unseenCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                        : const Icon(Icons.chat, color: Colors.green),
                    onTap: () async {
                      // Update lastRead immediately
                      await FirebaseDatabase.instance
                          .ref('chats/$chatId/lastRead/${widget.user.uid}')
                          .set(ServerValue.timestamp);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatId,
                            peerId: donorUid,
                            peerName: donorData['name'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
