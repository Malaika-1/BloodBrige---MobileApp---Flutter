import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImpactStats extends StatefulWidget {
  const ImpactStats({super.key});

  @override
  State<ImpactStats> createState() => _ImpactStatsState();
}

class _ImpactStatsState extends State<ImpactStats> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int totalDonationsMade = 0;
  int totalRequestsAccepted = 0;
  int totalBloodUnits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenToStats();
  }

  void _listenToStats() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Real-time listener to the user's Firestore document
    _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          totalDonationsMade = data?['totalDonationsMade'] ?? 0;
          totalRequestsAccepted = data?['totalRequestsAccepted'] ?? 0;
          totalBloodUnits = data?['totalBloodUnits'] ?? 0;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxValue = [
      totalDonationsMade,
      totalRequestsAccepted,
      totalBloodUnits
    ].reduce((a, b) => a > b ? a : b);

    const double cardHeight = 250;
    const double paddingTopBottom = 10 + 10;
    const double titleHeight = 30;
    const double spacingAfterTitle = 10;
    final double availableBarHeight =
        cardHeight - paddingTopBottom - titleHeight - spacingAfterTitle - 40;

    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const Text(
                "Your Impact Stats",
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: "Ubuntu",
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildVerticalStatBar(
                      "Donations", totalDonationsMade, Colors.red, maxValue, availableBarHeight),
                  _buildVerticalStatBar(
                      "Requests", totalRequestsAccepted, Colors.orange, maxValue, availableBarHeight),
                  _buildVerticalStatBar(
                      "Blood Units", totalBloodUnits, Colors.green, maxValue, availableBarHeight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalStatBar(
      String label, int value, Color color, int maxValue, double maxBarHeight) {
    double percentage = maxValue > 0 ? value / maxValue : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("$value", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: maxBarHeight,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: maxBarHeight * percentage,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
