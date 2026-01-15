import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upload_proof_page.dart'; // Make sure this import points to your file

class PostRequestPage extends StatefulWidget {
  const PostRequestPage({super.key});

  @override
  State<PostRequestPage> createState() => _PostRequestPageState();
}

class _PostRequestPageState extends State<PostRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedBloodGroup;
  String? _currentAddress;
  Position? _currentPosition;
  bool _isSubmitting = false;

  late DatabaseReference _database;

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instance.ref("requests");
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    setState(() => _currentAddress = "Fetching location...");

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _currentPosition = position;

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      _currentAddress = "${place.locality}, ${place.subAdministrativeArea}, ${place.country}";
      _locationController.text = _currentAddress!;
    } else {
      _currentAddress = "Lat:${position.latitude}, Lon:${position.longitude}";
      _locationController.text = _currentAddress!;
    }
    setState(() {});
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a blood group")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final currentUser = FirebaseAuth.instance.currentUser;

    try {
      // Create a new request reference
      final newRequestRef = _database.push();

      final request = {
        "uid": currentUser?.uid,
        "name": _nameController.text.trim(),
        "bloodGroup": _selectedBloodGroup,
        "location": _locationController.text.isNotEmpty
            ? _locationController.text.trim()
            : (_currentAddress ?? "Unknown"),
        "contact": _contactController.text.trim(),
        "timestamp": DateTime.now().toIso8601String(),
        "latitude": _currentPosition?.latitude,
        "longitude": _currentPosition?.longitude,

        // Added fields exactly as you requested
        "acceptedBy": null,
        "acceptedByName": null,

        "status": "pending",
      };

      // Save request
      await newRequestRef.set(request);

      // Get generated request ID
      final requestId = newRequestRef.key;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Request posted successfully!"),
            backgroundColor: Colors.green),
      );

      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _contactController.clear();
      _locationController.clear();

      setState(() {
        _selectedBloodGroup = null;
        _currentAddress = null;
        _currentPosition = null;
      });

    
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error posting request: $e"),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Post Blood Request",
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
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Enter Request Details",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Ubuntu",
                          letterSpacing: 2),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 600,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Please enter your name" : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 600,
                      child: DropdownButtonFormField<String>(
                        value: _selectedBloodGroup,
                        decoration: InputDecoration(
                          labelText: "Select Blood Group",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        items: bloodGroups
                            .map((group) =>
                                DropdownMenuItem(value: group, child: Text(group)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedBloodGroup = value),
                        validator: (value) =>
                            value == null ? "Please select a blood group" : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 600,
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: "Enter Location (or use current location)",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) &&
                                    _currentAddress == null
                                ? "Please provide a location"
                                : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      label: const Text(
                        "Use Current Location",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 135, 9, 13),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 600,
                      child: TextFormField(
                        controller: _contactController,
                        decoration: InputDecoration(
                          labelText: "Contact Number",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter contact number" : null,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Request",
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                    if (_currentAddress != null)
                      Text("Current Location: $_currentAddress",
                          style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
