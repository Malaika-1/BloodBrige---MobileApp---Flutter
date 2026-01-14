import 'package:bloodbridge/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'splash_screen.dart';
import 'dashboard/admin_dashboard.dart';
import 'dashboard/donor_dashboard.dart';
import 'dashboard/recipient_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Bridge',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const Signup(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/donorDashboard': (context) => const DonorDashboard(),
        '/recipientDashboard': (context) => const RecipientDashboard(),
      },
    );
  }
}
