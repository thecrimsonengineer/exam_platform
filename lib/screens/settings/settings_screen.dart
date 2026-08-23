import 'package:flutter/material.dart';

import '../../services/auth/auth_state_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthStateService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Sign out of your current account'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
