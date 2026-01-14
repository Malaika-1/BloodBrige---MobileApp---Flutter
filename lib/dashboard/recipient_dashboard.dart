import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../login.dart';
import 'recipient_screens/postreq.dart';
import 'recipient_screens/find_donors.dart';
import 'recipient_screens/RequestHistoryPage.dart';
import 'recipient_screens/dashboard_stats.dart';
import 'recipient_screens/upload_proof_page.dart';
import 'ChatPage .dart';
import 'recipient_screens/health_guidelines.dart';
import 'recipient_screens/recipient_profile.dart';
import 'recipient_screens/recipient_chats_page.dart';

class RecipientDashboard extends StatefulWidget {
  const RecipientDashboard({super.key});

  @override
  State<RecipientDashboard> createState() => _RecipientDashboardState();
}

class _RecipientDashboardState extends State<RecipientDashboard> {
  User? _currentUser;
  bool _loading = true;
  final DatabaseReference _requestsRef = FirebaseDatabase.instance.ref("requests");

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loading = false;
  }

  void _showUploadProofOptions() {
    if (_currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Request"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<DatabaseEvent>(
            stream: _requestsRef
                .orderByChild("uid")
                .equalTo(_currentUser!.uid)
                .onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Center(child: Text("No requests found"));
              }
              final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
              final requests = data.entries.toList();
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final key = requests[index].key;
                  final value = Map<String, dynamic>.from(requests[index].value);
                  final bloodGroup = value['bloodGroup'] ?? "Unknown";
                  final status = value['status'] ?? "pending";
                  return ListTile(
                    title: Text("Request for $bloodGroup"),
                    subtitle: Text("Status: $status"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadProofPage(requestId: key!),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Recipient Dashboard",
          style: TextStyle(
            fontSize: 26,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String drawerName = "Recipient";
                String drawerEmail = "recipient@example.com";

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  drawerName = data?['name'] ?? drawerName;
                  drawerEmail = data?['email'] ?? drawerEmail;
                }

                return UserAccountsDrawerHeader(
                  accountName: Text(drawerName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(drawerEmail),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 235, 208, 209),
                    child: Text(
                      drawerName.isNotEmpty ? drawerName[0].toUpperCase() : "R",
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 135, 9, 13),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.post_add, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Post Request"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PostRequestPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Find Donors"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindDonorsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Upload Proof"),
              onTap: _showUploadProofOptions,
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Request History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RequestHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Health & Safety Guidelines"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthGuidelinesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipientProfile()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: const [
              SizedBox(height: 12),
              DashboardStats(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          if (_currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipientChatsPage(user: _currentUser!),
              ),
            );
          }
        },
      ),
    );
  }
}
