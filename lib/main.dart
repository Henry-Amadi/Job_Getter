import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';
import 'pages/dashboard.dart';
import 'pages/employer_dashboard.dart';
import 'pages/authentication_page.dart';
import 'pages/post_job_page.dart';
import 'pages/company_profile_page.dart';
import 'pages/manage_jobs_page.dart';
import 'pages/job_applications_page.dart';
import 'pages/notifications_page.dart';
import 'pages/user_profile_page.dart';
import 'pages/wallet_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job Getter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        '/authentication': (context) => const AuthenticationPage(),
        '/dashboard': (context) => const Dashboard(),
        '/employer-dashboard': (context) => const EmployerDashboard(),
        '/post-job': (context) => PostJobPage(),
        '/company-profile': (context) => CompanyProfilePage(),
        '/manage-jobs': (context) => ManageJobsPage(),
        '/applications': (context) => const JobApplicationsPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/user-profile': (context) => const UserProfilePage(),
        '/wallet': (context) => const WalletPage(),
      },
    );
  }
}
