import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../login.dart'; // adjust path based on your folder structure


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontSize: 26,
            letterSpacing: 3,
            fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      drawer: _buildDrawer(),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // 🔹 Drawer for admin
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children:  [
          UserAccountsDrawerHeader(
            accountName: Text("Admin"),
            accountEmail: Text("admin@bloodbridge.com"),
            currentAccountPicture: CircleAvatar(
              child: Text("A"),
              backgroundColor: Color.fromARGB(255, 235, 208, 209),
            ),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 135, 9, 13),
            ),
          ),
          ListTile( leading: Icon(Icons.verified_user), title: Text("Verify Users"), ),
          ListTile(  leading: Icon(Icons.report), title: Text("Manage Reports"),  ),
          ListTile(  leading: Icon(Icons.visibility), title: Text("View Reports"),  ),
          ListTile(  leading: Icon(Icons.favorite),  title: Text("Track Donations"),   ),
          Divider(),
             ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut(); // Sign out user

                    // Navigate back to login screen and remove all previous routes
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),

        ],
      ),
    );
  }

  // 🔹 Body content for admin
  Widget _buildBody() {
    return Center(
      child: SizedBox(
        width: 700,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.6,
          padding: const EdgeInsets.all(20),
          children: [
            _featureCard(Icons.verified_user, "Verify Users", Colors.blue),
            _featureCard(Icons.report, "Manage Reports", Colors.red),
            _featureCard(Icons.analytics, "Analytics Dashboard", Colors.green),
            _featureCard(Icons.favorite, "Track Donations", Colors.purple),
          ],
        ),
      ),
    );
  }

  // Reusable feature card
  Widget _featureCard(IconData icon, String title, Color color) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Add navigation for each feature
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title clicked!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 45),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
