import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonorNearbyRequests extends StatefulWidget {
  const DonorNearbyRequests({super.key});

  @override
  State<DonorNearbyRequests> createState() => _DonorNearbyRequestsState();
}

class _DonorNearbyRequestsState extends State<DonorNearbyRequests> {
  final DatabaseReference _requestsRef = FirebaseDatabase.instance.ref("requests");
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Position? _donorPosition;
  bool _loading = true;
  bool _acceptingRequest = false;
  List<Map<String, dynamic>> _nearbyRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchDonorLocation();
  }

  Future<void> _fetchDonorLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location to see nearby requests')),
      );
      setState(() => _loading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      setState(() => _loading = false);
      return;
    }

    _donorPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _fetchNearbyRequests();
  }

  Future<void> _fetchNearbyRequests() async {
    if (_donorPosition == null) return;

    DataSnapshot snapshot = await _requestsRef.get();
    List<Map<String, dynamic>> nearby = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        double reqLat = value['latitude'] ?? 0.0;
        double reqLon = value['longitude'] ?? 0.0;

        double distance = Geolocator.distanceBetween(
          _donorPosition!.latitude,
          _donorPosition!.longitude,
          reqLat,
          reqLon,
        );

        if (distance <= 10000 && value['status'] == 'pending') {
          nearby.add({
            "key": key,
            "recipientName": value['recipientName'] ?? "",
            "bloodGroup": value['bloodGroup'] ?? "",
            "location": value['location'] ?? "",
            "recipientContact": value['contact'] ?? "",
            "distance": distance,
          });
        }
      });
    }

    nearby.sort((a, b) => a['distance'].compareTo(b['distance']));

    setState(() {
      _nearbyRequests = nearby;
      _loading = false;
    });
  }

  Future<void> _acceptRequest(String key) async {
    final User? donor = FirebaseAuth.instance.currentUser;
    if (donor == null) return;

    setState(() => _acceptingRequest = true);

    try {
      DocumentSnapshot donorDoc = await _firestore.collection("users").doc(donor.uid).get();
      String donorName = donorDoc.exists ? donorDoc['name'] : "Donor";
      String donorContact = donorDoc.exists ? donorDoc['contact'] : "Not Provided";

      // Update Realtime Database request
      await _requestsRef.child(key).update({
        "acceptedBy": donor.uid,
        "acceptedByName": donorName,
        "acceptedByContact": donorContact,
        "status": "accepted",
        "acceptedAt": ServerValue.timestamp,
      });

      // Update donor stats in Firestore
      await _firestore.collection("users").doc(donor.uid).update({
        "totalRequestsAccepted": FieldValue.increment(1),
        "totalBloodUnits": FieldValue.increment(1),
        "totalDonationsMade": FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request accepted!"), backgroundColor: Colors.green),
      );

      _fetchNearbyRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting request: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _acceptingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nearby Requests",
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
          : _nearbyRequests.isEmpty
              ? const Center(
                  child: Text("No nearby requests found", style: TextStyle(fontSize: 18)),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _nearbyRequests.length,
                    itemBuilder: (context, index) {
                      final req = _nearbyRequests[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.bloodtype, color: Colors.red),
                          title: Text(
                            "${req['recipientName']} (${req['bloodGroup']})",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "${req['location']}\n"
                            "${(req['distance'] / 1000).toStringAsFixed(2)} km away\n"
                            "Contact: ${req['recipientContact']}",
                          ),
                          isThreeLine: true,
                          trailing: _acceptingRequest
                              ? const SizedBox(
                                  width: 80,
                                  height: 35,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : ElevatedButton(
                                  onPressed: () => _acceptRequest(req['key']),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text("Accept"),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
