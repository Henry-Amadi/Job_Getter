import 'package:flutter/material.dart';
import 'package:job_getter_application/pages/dashboard.dart';
import 'package:job_getter_application/pages/employer_dashboard.dart';
import 'package:job_getter_application/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is logged in
          if (snapshot.hasData) {
            // Check if user is an employer (based on display name)
            final user = snapshot.data;
            if (user != null) {
              // Check if this is an employer account
              if (user.displayName != null && user.displayName!.isNotEmpty) {
                // This is an employer account (has company name as display name)
                return const EmployerDashboard();
              } else {
                // This is a regular user account (no display name or empty display name)
                return const Dashboard();
              }
            }
            return const Dashboard();
          }
          // User is not logged in
          else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}