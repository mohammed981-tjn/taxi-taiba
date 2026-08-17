import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/pages/home_page.dart';

import 'intro_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!context.mounted) return;
      FirebaseAuth.instance.currentUser == null
          ? Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const IntroPage(),
              ),
            )
          : Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
    });

    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/oago_logo.png'),
      ),
    );
  }
}
