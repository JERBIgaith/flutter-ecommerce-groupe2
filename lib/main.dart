import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_theme.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'StyleHub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// AuthGate widget that shows LoginScreen or HomeScreen based on auth state
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _profileLoaded = false;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return StreamBuilder(
      stream: authController.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // User is logged in
          if (!_profileLoaded && !user.isAnonymous) {
            // Load profile once for non-anonymous users
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authController.loadProfile();
            });
            _profileLoaded = true;
          }
          return const HomeScreen();
        } else {
          // User is not logged in
          _profileLoaded = false;
          return const LoginScreen();
        }
      },
    );
  }
}
