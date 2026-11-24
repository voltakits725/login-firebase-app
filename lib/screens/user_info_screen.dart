import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_firebase/fcm_token_card.dart'; // <-- BARU
import 'package:login_firebase/widgets/custom_app_bar.dart';

class UserInfoScreen extends StatelessWidget {
  final User user;

  const UserInfoScreen({super.key, required this.user});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard User',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Login Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UID: ${user.uid}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${user.email ?? "Tidak ada email"}'),
                      const SizedBox(height: 8),
                      Text(
                        'Email Terverifikasi: ${user.emailVerified ? "Ya" : "Tidak"}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Terakhir Login: ${user.metadata.lastSignInTime.toString()}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const FcmTokenCard(), // <-- BARU (hapus 'const' jika constructor-nya non-const)
            ],
          ),
        ),
      ),
    );
  }
}