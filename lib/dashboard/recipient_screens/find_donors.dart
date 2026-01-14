import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../recipient_screens/postreq.dart';

class FindDonorsPage extends StatefulWidget {
  const FindDonorsPage({super.key});

  @override
  State<FindDonorsPage> createState() => _FindDonorsPageState();
}

class _FindDonorsPageState extends State<FindDonorsPage> {
  final _dbRef = FirebaseDatabase.instance.ref();

  Future<void> _showHealthInfo(String donorUid) async {
    final snapshot = await _dbRef.child('donorsHealthInfo/$donorUid').get();

    if (!snapshot.exists) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Health Info"),
          content: const Text("No health info available"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close")),
          ],
        ),
      );
      return;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Health Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Blood Pressure: ${data['bloodPressure'] ?? 'Not Provided'}"),
            Text("Weight: ${data['weight'] ?? 'Not Provided'}"),
            Text("Last Donation: ${data['lastDonationDate'] ?? 'Not Provided'}"),
            Text(
                "Medical Conditions: ${data['medicalConditions'] ?? 'Not Provided'}"),
            Text("Medications: ${data['medications'] ?? 'Not Provided'}"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Available Donors",
          style: TextStyle(
            fontSize: 26,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('availability', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No donors available currently"));
          }

          final donors = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donors.length,
            itemBuilder: (context, index) {
              final donor = donors[index];
              final data = donor.data() as Map<String, dynamic>;
              final donorUid = donor.id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${data['name'] ?? 'No Name'} (${data['bloodGroup'] ?? 'Unknown'})",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text("Email: ${data['email'] ?? 'No Email'}"),
                      Text("Contact: ${data['contact'] ?? 'Not Provided'}"),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _showHealthInfo(donorUid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 135, 9, 13),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: const Text(
                              "Health Info",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PostRequestPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 135, 9, 13),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: const Text(
                              "Request",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
