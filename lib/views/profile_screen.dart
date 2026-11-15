import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authController = context.read<AuthController>();
    await authController.logout();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final themeController = context.watch<ThemeController>();
    final profile = authController.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Profile info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.person_outlined),
                      title: const Text('Name'),
                      subtitle: Text(profile?.name ?? 'Guest'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(profile?.email ?? 'Not available'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (profile?.address != null)
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('Address'),
                        subtitle: Text(profile!.address!),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Theme selector card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.brightness_5_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.brightness_2_outlined),
                        ),
                      ],
                      selected: {themeController.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        themeController.setThemeMode(newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
