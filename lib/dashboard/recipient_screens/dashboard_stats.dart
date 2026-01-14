import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    final dbRef = FirebaseDatabase.instance.ref("requests");

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.orderByChild("uid").equalTo(_currentUser!.uid).onValue,
      builder: (context, snapshot) {
        int totalRequests = 0;
        int pendingRequests = 0;
        int acceptedRequests = 0;
        int donationsReceived = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          totalRequests = data.length;

          data.forEach((key, value) {
            final status = value['status'] ?? 'pending';
            if (status == 'pending') pendingRequests++;
            if (status == 'accepted') acceptedRequests++;
          });

          donationsReceived = acceptedRequests;
        }

        final maxValue = [
          totalRequests,
          pendingRequests,
          acceptedRequests,
          donationsReceived
        ].reduce((a, b) => a > b ? a : b);

        const double cardHeight = 250;
        const double barMaxHeight = 120;

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 40), // space from top
            child: SizedBox(
              width:800,
              height: cardHeight,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        "Your Requests Overview",
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: "Ubuntu",
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildVerticalBar("Total", totalRequests,
                                Colors.red, maxValue, barMaxHeight),
                            _buildVerticalBar("Pending", pendingRequests,
                                Colors.orange, maxValue, barMaxHeight),
                            _buildVerticalBar("Accepted", acceptedRequests,
                                Colors.green, maxValue, barMaxHeight),
                            _buildVerticalBar("Donations Received", donationsReceived,
                                Colors.blue, maxValue, barMaxHeight),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalBar(
      String label, int value, Color color, int maxValue, double maxHeight) {
    double percentage = maxValue > 0 ? value / maxValue : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("$value", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: 50, // narrower bar width
          height: maxHeight,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: maxHeight * percentage,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
