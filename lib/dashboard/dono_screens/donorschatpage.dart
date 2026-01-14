import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ChatPage .dart';

class DonorChatsPage extends StatelessWidget {
  final User donor;
  final DatabaseReference requestsRef =
      FirebaseDatabase.instance.ref("requests");

  DonorChatsPage({super.key, required this.donor});

  String generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode
        ? '${uid1}_$uid2'
        : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: requestsRef
            .orderByChild("acceptedBy")
            .equalTo(donor.uid)
            .onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No active chats"));
          }

          final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map);

          /// 🔹 UNIQUE recipients only (by UID)
          final Set<String> recipientUids = {};

          data.forEach((key, value) {
            final v = Map<String, dynamic>.from(value);
            if (v['uid'] != null) {
              recipientUids.add(v['uid']);
            }
          });

          if (recipientUids.isEmpty) {
            return const Center(child: Text("No active chats"));
          }

          return ListView(
            children: recipientUids.map((recipientUid) {
              final chatId = generateChatId(donor.uid, recipientUid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(recipientUid)
                    .get(),
                builder: (context, userSnap) {
                  String recipientName = "Recipient";

                  if (userSnap.hasData && userSnap.data!.exists) {
                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>?;
                    recipientName = userData?['name'] ?? "Recipient";
                  }

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(recipientName),
                    subtitle: const Text("Tap to chat"),
                    trailing:
                        const Icon(Icons.chat, color: Colors.green),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatId,
                            peerId: recipientUid,
                            peerName: recipientName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
