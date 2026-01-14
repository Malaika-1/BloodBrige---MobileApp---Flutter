import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DonorHealthInfo extends StatefulWidget {
  const DonorHealthInfo({super.key});

  @override
  State<DonorHealthInfo> createState() => _DonorHealthInfoState();
}

class _DonorHealthInfoState extends State<DonorHealthInfo> {
  final _bloodPressureController = TextEditingController();
  final _weightController = TextEditingController();
  final _lastDonationController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();

  final _dbRef = FirebaseDatabase.instance.ref();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadHealthInfo();
  }

  Future<void> _loadHealthInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _dbRef.child('donorsHealthInfo/$uid').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      _bloodPressureController.text = data['bloodPressure'] ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      _lastDonationController.text = data['lastDonationDate'] ?? '';
      _conditionsController.text = data['medicalConditions'] ?? '';
      _medicationsController.text = data['medications'] ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveHealthInfo() async {
    if (_bloodPressureController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _lastDonationController.text.isEmpty ||
        _conditionsController.text.isEmpty ||
        _medicationsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _dbRef.child('donorsHealthInfo/$uid').set({
        'bloodPressure': _bloodPressureController.text.trim(),
        'weight': _weightController.text.trim(),
        'lastDonationDate': _lastDonationController.text.trim(),
        'medicalConditions': _conditionsController.text.trim(),
        'medications': _medicationsController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Health info saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // light background
      appBar: AppBar(
        title: const Text("Health Info" , style: TextStyle(
            fontSize: 26,
             fontFamily: "Ubuntu",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
        ),),
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SizedBox(
                width: 600, // centered box width
                child: Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField("Blood Pressure e.g 120/80", Icons.monitor_heart, _bloodPressureController),
                        const SizedBox(height: 15),
                        _buildTextField("Weight (kg)", Icons.fitness_center, _weightController,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 15),
                        _buildTextField("Last Donation Date", Icons.calendar_today, _lastDonationController),
                        const SizedBox(height: 15),
                        _buildTextField("Medical Conditions", Icons.medical_services, _conditionsController),
                        const SizedBox(height: 15),
                        _buildTextField("Medications", Icons.medication, _medicationsController),
                        const SizedBox(height: 30),
                        _saving
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _saveHealthInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 135, 9, 13),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text(
                                  "Save Health Info",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
