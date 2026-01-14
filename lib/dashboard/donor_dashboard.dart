import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../login.dart';
import 'dono_screens/donorhistory.dart';
import 'dono_screens/nearbyreq.dart';
import 'dono_screens/DonorHealthInfo.dart';
import 'dono_screens/impact_stats.dart';
import 'ChatPage .dart';
import 'dono_screens/health_guidelines_page.dart';
import 'dono_screens/donor_profile.dart';
import 'dono_screens/donorschatpage.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final DatabaseReference _requestsRef = FirebaseDatabase.instance.ref("requests");

  User? _currentUser;
  bool _loading = true;
  bool _availability = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _availability = data?['availability'] ?? false;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability(bool newValue) async {
    if (_currentUser == null) return;
    setState(() => _availability = newValue);
    await _firestore.collection('users').doc(_currentUser!.uid).update({
      'availability': newValue,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  String generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Donor Dashboard",
          style: TextStyle(
            fontSize: 26,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(_currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                String drawerName = "Blood Donor";
                String drawerEmail = "donor@example.com";

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  drawerName = data?['name'] ?? _currentUser!.displayName ?? drawerName;
                  drawerEmail = data?['email'] ?? _currentUser!.email ?? drawerEmail;
                }

                return UserAccountsDrawerHeader(
                  accountName: Text(drawerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(drawerEmail),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        color: Color.fromARGB(255, 135, 9, 13), size: 40),
                  ),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 135, 9, 13),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Health Info"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorHealthInfo())),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Donation History"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorHistory())),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Nearby Requests"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorNearbyRequests())),
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Health & Safety Guidelines"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthGuidelinesPage())),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Profile"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorProfile())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color.fromARGB(255, 135, 9, 13)),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 300,
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bloodtype, size: 60, color: Color.fromARGB(255, 135, 9, 13)),
                            const SizedBox(height: 20),
                            const Text(
                              "Availability Status",
                              style: TextStyle(
                                fontSize: 24,
                                fontFamily: "Ubuntu",
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Switch.adaptive(
                              value: _availability,
                              activeColor: Colors.green,
                              onChanged: _toggleAvailability,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _availability ? "You are available to donate" : "You are unavailable",
                              style: TextStyle(
                                fontSize: 16,
                                color: _availability ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(flex: 1, child: SizedBox(height: 300, child: ImpactStats())),
              ],
            ),
          ],
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
                builder: (_) => DonorChatsPage(donor: _currentUser!),
              ),
            );
          }
        },
      ),
    );
  }
}
