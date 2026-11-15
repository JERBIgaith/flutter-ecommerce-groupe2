import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../views/register_screen.dart';

/// Guest guard to prevent anonymous users from using protected features
class GuestGuard {
  /// Check if action is allowed. Shows bottom sheet for guests and returns false.
  /// Returns true for signed-in users.
  static Future<bool> check(BuildContext context, {required bool isGuest}) async {
    if (!isGuest) {
      return true;
    }

    // Show bottom sheet for guests
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => const _GuestPromptSheet(),
    );

    return result ?? false;
  }
}

class _GuestPromptSheet extends StatelessWidget {
  const _GuestPromptSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Create an account to use this feature',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final authController = context.read<AuthController>();
              await authController.logout();
              
              if (!context.mounted) return;
              
              Navigator.pop(context, false);
              
              if (!context.mounted) return;
              
              // Navigate to register screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
            child: const Text('Create account'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final authController = context.read<AuthController>();
              await authController.logout();
              
              if (!context.mounted) return;
              
              Navigator.pop(context, false);
            },
            child: const Text('Log in'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
