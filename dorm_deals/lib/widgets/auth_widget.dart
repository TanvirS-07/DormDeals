import 'package:flutter/material.dart';
import 'package:dorm_deals/dorm_deals.dart';
import 'package:dorm_deals/widgets/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWidget extends StatelessWidget {
  const AuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Reacts to Firebase Auth changes and switches between login and marketplace screens.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/dorm_deals_logo.png',
                  width: 64,
                  height: 64,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          return const DormDeals();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
