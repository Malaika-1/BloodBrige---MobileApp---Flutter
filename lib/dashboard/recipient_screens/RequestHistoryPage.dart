import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  final _dbRef = FirebaseDatabase.instance.ref("requests");
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  // Edit request
  void _editRequest(String key, Map<dynamic, dynamic> request) {
    final _locationController =
        TextEditingController(text: request['location'] ?? "");
    final _contactController =
        TextEditingController(text: request['contact'] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: "Contact"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbRef.child(key).update({
                "location": _locationController.text.trim(),
                "contact": _contactController.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Delete / Cancel request
  void _deleteRequest(String key) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Request"),
        content: const Text("Are you sure you want to delete this request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbRef.child(key).remove();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    if (ts is String) {
      try {
        return DateTime.parse(ts);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Request History",
          style: TextStyle(
            fontSize: 26,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.orderByChild("uid").equalTo(_currentUser!.uid).onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = snapshot.data!;
          final dataSnapshot = event.snapshot;

          if (dataSnapshot.value == null) {
            return const Center(child: Text("No requests found"));
          }

          final Map<dynamic, dynamic> requests =
              dataSnapshot.value as Map<dynamic, dynamic>;

          final requestList = requests.entries.toList();

          // Sort newest → oldest safely
          requestList.sort((a, b) {
            final timeA = _parseTimestamp(a.value['timestamp']);
            final timeB = _parseTimestamp(b.value['timestamp']);
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requestList.length,
            itemBuilder: (context, index) {
              final key = requestList[index].key;
              final request =
                  requestList[index].value as Map<dynamic, dynamic>;

              String status = (request['status'] ?? 'pending').toLowerCase();
              String acceptedBy = request['acceptedByName'] ?? '';
              String donorContact = request['donorContact'] ?? '';

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
                        "${request['name'] ?? 'No Name'} (${request['bloodGroup'] ?? 'Unknown'})",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text("Location: ${request['location'] ?? 'Unknown'}"),
                      Text("Contact: ${request['contact'] ?? 'N/A'}"),
                      Text("Status: ${status.toUpperCase()}"),

                      if (acceptedBy.isNotEmpty)
                        Text("Accepted by: $acceptedBy"),

                      if (donorContact.isNotEmpty)
                        Text("Donor Contact: $donorContact"),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'pending') ...[
                            ElevatedButton(
                              onPressed: () => _editRequest(key, request),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 135, 9, 13),
                              ),
                              child: const Text(
                                "Edit",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _deleteRequest(key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 135, 9, 13),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ] else ...[
                            ElevatedButton(
                              onPressed: () => _deleteRequest(key),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 135, 9, 13),
                              ),
                              child: const Text(
                                "Delete",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      )
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
