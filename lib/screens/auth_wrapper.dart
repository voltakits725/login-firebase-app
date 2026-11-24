import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'user_info_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Menampilkan loading saat mengecek status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Jika terdapat data user (sudah login), tampilkan halaman info
        if (snapshot.hasData) {
          return UserInfoScreen(user: snapshot.data!);
        }
        // Jika tidak ada data user, tampilkan halaman login
        return const LoginScreen();
      },
    );
  }
}