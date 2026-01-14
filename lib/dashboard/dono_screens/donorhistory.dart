import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DonorHistory extends StatefulWidget {
  const DonorHistory({super.key});

  @override
  State<DonorHistory> createState() => _DonorHistoryState();
}

class _DonorHistoryState extends State<DonorHistory> {
  final DatabaseReference _requestsRef = FirebaseDatabase.instance.ref("requests");
  bool _loading = true;
  List<Map<String, dynamic>> _donorRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchDonorHistory();
  }

  Future<void> _fetchDonorHistory() async {
    final User? donor = FirebaseAuth.instance.currentUser;
    if (donor == null) return;

    DataSnapshot snapshot = await _requestsRef.get();
    List<Map<String, dynamic>> history = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        Map<String, dynamic> req = Map<String, dynamic>.from(value);

        // ✅ Check the correct donor UID field
        if ((req['status']?.toString().toLowerCase() ?? '') == 'accepted' &&
            req['acceptedBy'] == donor.uid) {
          history.add({
            "key": key,
            "recipientName": req['name'] ?? "Unknown",
            "bloodGroup": req['bloodGroup'] ?? "",
            "location": req['location'] ?? "",
            "contact": req['contact'] ?? "",
            "donorContact": req['donorContact'] ?? "",
          });
        }
      });
    }

    setState(() {
      _donorRequests = history;
      _loading = false;
    });
  }

  Future<void> _deleteRequest(String key) async {
    try {
      await _requestsRef.child(key).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donation record deleted"),
          backgroundColor: Colors.red,
        ),
      );
      _fetchDonorHistory(); // refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting record: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Donation History",
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _donorRequests.isEmpty
              ? const Center(
                  child: Text("No donations yet", style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _donorRequests.length,
                  itemBuilder: (context, index) {
                    final req = _donorRequests[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.bloodtype, color: Colors.red),
                        title: Text("${req['recipientName']} (${req['bloodGroup']})",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Location: ${req['location']}\nRecipient Contact: ${req['contact']}\nYour Contact: ${req['donorContact']}"),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Confirm Delete"),
                                content: const Text(
                                    "Are you sure you want to delete this record?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _deleteRequest(req['key']);
                                    },
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
