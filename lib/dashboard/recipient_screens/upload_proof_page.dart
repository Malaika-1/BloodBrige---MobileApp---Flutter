import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class UploadProofPage extends StatefulWidget {
  final String requestId; // ID of the selected request

  const UploadProofPage({super.key, required this.requestId});

  @override
  State<UploadProofPage> createState() => _UploadProofPageState();
}

class _UploadProofPageState extends State<UploadProofPage> {
  final _dbRef = FirebaseDatabase.instance.ref("requests");
  final _storageRef = FirebaseStorage.instance.ref();
  final _auth = FirebaseAuth.instance;

  Map<String, dynamic>? requestData; // Info about the request
  List<Map<String, dynamic>> uploadedFiles = []; // {name, url}
  bool _isUploading = false;

  late DatabaseReference _requestRef;
  late StreamSubscription<DatabaseEvent> _requestSubscription;

  @override
  void initState() {
    super.initState();

    _requestRef = _dbRef.child(widget.requestId);

    // Listen for real-time updates of request info
    _requestSubscription = _requestRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          requestData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });

    _loadExistingProofs();
  }

  @override
  void dispose() {
    _requestSubscription.cancel();
    super.dispose();
  }

  // Load previously uploaded proofs
  Future<void> _loadExistingProofs() async {
    final snapshot = await _requestRef.child("proofs").get();
    if (snapshot.exists && snapshot.value != null) {
      final proofs = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        uploadedFiles = proofs.entries
            .map((e) => {"name": e.key, "url": e.value})
            .toList();
      });
    }
  }

  // Pick and upload files (supports mobile & web)
  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: kIsWeb, // important for web
    );

    if (result == null) return; // user canceled

    setState(() => _isUploading = true);

    try {
      for (var file in result.files) {
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
        final storageFileRef = _storageRef
            .child("proofs/${_auth.currentUser!.uid}/${widget.requestId}/$fileName");

        if (kIsWeb) {
          if (file.bytes != null) {
            await storageFileRef.putData(file.bytes!);
          } else {
            throw Exception("File bytes not found on web");
          }
        } else {
          if (file.path != null) {
            File localFile = File(file.path!);
            await storageFileRef.putFile(localFile);
          } else {
            throw Exception("File path not found");
          }
        }

        final downloadUrl = await storageFileRef.getDownloadURL();

        // Save URL in Realtime DB under proofs
        await _requestRef.child("proofs").child(fileName).set(downloadUrl);

        uploadedFiles.add({"name": fileName, "url": downloadUrl});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading files: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Delete uploaded file
  Future<void> _deleteFile(Map<String, dynamic> file) async {
    try {
      await _storageRef
          .child("proofs/${_auth.currentUser!.uid}/${widget.requestId}/${file['name']}")
          .delete();

      await _requestRef.child("proofs").child(file['name']).remove();

      setState(() {
        uploadedFiles.remove(file);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting file: $e")),
      );
    }
  }

  // Build ListTile for each uploaded file
  Widget _buildFileTile(Map<String, dynamic> file) {
    final isImage = file['url'].toString().endsWith(".jpg") ||
        file['url'].toString().endsWith(".jpeg") ||
        file['url'].toString().endsWith(".png");

    return ListTile(
      leading: isImage
          ? Image.network(file['url'], width: 50, height: 50, fit: BoxFit.cover)
          : const Icon(Icons.picture_as_pdf, size: 50, color: Colors.redAccent),
      title: Text(file['name']),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteFile(file),
      ),
      onTap: () {
        // Optional: preview image or open PDF in web
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloodGroup = requestData?['bloodGroup'] ?? "Unknown";
    final status = requestData?['status'] ?? "pending";
    final name = requestData?['name'] ?? "";
    final location = requestData?['location'] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload Proof / Documents",
          style: TextStyle(
            fontSize: 22,
            fontFamily: "Ubuntu",
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Display request info in real-time
            Card(
              color: Colors.grey[100],
              elevation: 4,
              child: ListTile(
                title: Text("Request: $bloodGroup"),
                subtitle: Text("Name: $name\nLocation: $location\nStatus: $status"),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadFile,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Select & Upload Files", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 135, 9, 13),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: uploadedFiles.isEmpty
                  ? const Center(child: Text("No files uploaded yet"))
                  : ListView.builder(
                      itemCount: uploadedFiles.length,
                      itemBuilder: (context, index) =>
                          _buildFileTile(uploadedFiles[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
