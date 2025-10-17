import 'dart:async';
import 'package:flutter/material.dart';
import 'package:job_getter_application/pages/authentication_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Navigate to appropriate page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthenticationPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001C32),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.only(
              left: 40.0, right: 40, bottom: 40, top: 100), 
            child: Image.asset(
              'lib/assets/logo/logo.jpg',
              width: 500, 
              height: 400, 
              fit: BoxFit.contain, 
            ),
          ), 

          // Main heading
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Where All Jobs are found at your convenience",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),

          // Loading indicator
          const Padding(
            padding: EdgeInsets.only(bottom: 50),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }
}
