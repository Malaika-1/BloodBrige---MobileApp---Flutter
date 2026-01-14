import 'package:flutter/material.dart';
import 'dashboard/admin_dashboard.dart';
import 'dashboard/donor_dashboard.dart';
import 'dashboard/recipient_dashboard.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _showResend = false;

  // 🔹 LOGIN FUNCTION
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a role")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showResend = false;
    });

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      //  Check if email verified
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Please verify your email before logging in. Check your inbox."),
          ),
        );

        setState(() {
          _showResend = true;
          _isLoading = false;
        });
        return;
      }

      // Fetch user role
      final userDoc =
          await _firestore.collection('users').doc(credential.user!.uid).get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found in database")),
        );
        return;
      }

      final storedRole = userDoc['role'];
      if (storedRole.toLowerCase() != _selectedRole!.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Role mismatch! You are registered as $storedRole."),
          ),
        );
        return;
      }

      // ✅ Navigate by role
      if (storedRole == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else if (storedRole == "donor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DonorDashboard()),
        );
      } else if (storedRole == "recipient") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipientDashboard()),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format.";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔹 RESEND VERIFICATION FUNCTION
  Future<void> _resendVerification() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent. Check your inbox."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend email: $e")),
      );
    }
  }

  // 🔹 FORGOT PASSWORD FUNCTION
  Future<void> _forgotPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Forgot Password?"),
        content: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(
            labelText: "Enter your email",
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter your email.")),
                );
                return;
              }
              try {
                await _auth.sendPasswordResetEmail(email: email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Password reset email sent successfully.")),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.message}")),
                );
              }
            },
            child: const Text("Send Reset Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B0000),
              Color(0xFFC62828),
              Color(0xFFFF5252),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 700,
            height: 650,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.bloodtype, size: 80, color: Color(0xFFB71C1C)),
                  const SizedBox(height: 10),
                  const Text(
                    "Blood Bridge",
                    style: TextStyle(
                      fontSize: 38,
                   fontFamily: "Ubuntu",
                  letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Login to your Account",
                    style: TextStyle(fontSize: 16, letterSpacing: 2),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Email Field
                  SizedBox(
                    width: 600,
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Password Field
                  SizedBox(
                    width: 600,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // 🔹 Forgot Password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPasswordDialog,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),

                  // 🔹 Role Dropdown
                  SizedBox(
                    width: 600,
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: "Select Role",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "donor", child: Text("Donor")),
                        DropdownMenuItem(
                            value: "recipient", child: Text("Recipient")),
                        DropdownMenuItem(
                            value: "admin", child: Text("Hospital Admin")),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedRole = value;
                      }),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔹 Login Button
                  SizedBox(
                    width: 600,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFF8B0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3)
                          : const Text("Sign In",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white)),
                    ),
                  ),

                  // 🔹 Resend verification
                  if (_showResend)
                    TextButton(
                      onPressed: _resendVerification,
                      child: const Text("Resend Verification Email",
                          style: TextStyle(color: Colors.blue)),
                    ),

                  const SizedBox(height: 20),
                  const Text("- Or sign in with -"),
                  const SizedBox(height: 20),

                  // 🔹 Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: const FaIcon(FontAwesomeIcons.google,
                              size: 40, color: Colors.red),
                          onPressed: () {}),
                      const SizedBox(width: 20),
                      IconButton(
                          icon: const FaIcon(FontAwesomeIcons.facebook,
                              size: 40, color: Colors.blue),
                          onPressed: () {}),
                      const SizedBox(width: 20),
                      IconButton(
                          icon: const FaIcon(FontAwesomeIcons.twitter,
                              size: 40, color: Colors.lightBlue),
                          onPressed: () {}),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Signup Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Signup()),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 