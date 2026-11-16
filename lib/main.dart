import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/favorite_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/admin_controller.dart';
import 'utils/app_theme.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'views/admin/admin_home_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => FavoriteController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
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

/// AuthGate widget routing by user role after sign-in
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _profileLoadingTriggered = false;
  bool _streamsStarted = false;
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final productController = context.watch<ProductController>();
    final favoriteController = context.watch<FavoriteController>();
    final cartController = context.watch<CartController>();
    final orderController = context.watch<OrderController>();
    final adminController = context.watch<AdminController>();

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

        // Reset tracking flags if user changes
        if (user?.uid != _lastUserId) {
          _profileLoadingTriggered = false;
          _streamsStarted = false;
          _lastUserId = user?.uid;
        }

        if (user != null) {
          // Logged in user or guest
          if (!user.isAnonymous) {
            final profile = authController.profile;

            // Profile loading state
            if (profile == null) {
              if (!_profileLoadingTriggered) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authController.loadProfile();
                });
                _profileLoadingTriggered = true;
              }
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Role-based routing
            final isAdmin = profile.isAdmin;

            if (isAdmin) {
              // Admin user
              if (!_streamsStarted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  productController.listenToProducts();
                  productController.listenToCategories();
                  adminController.listenToUsers();
                  adminController.listenToAllOrders();
                });
                _streamsStarted = true;
              }
              return const AdminHomeScreen();
            } else {
              // Standard registered user
              if (!_streamsStarted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  productController.listenToProducts();
                  productController.listenToCategories();
                  favoriteController.listenToFavorites(user.uid);
                  cartController.listenToCart(user.uid);
                  orderController.listenToOrders(user.uid);
                });
                _streamsStarted = true;
              }
              return const HomeScreen();
            }
          } else {
            // Anonymous Guest User
            if (!_streamsStarted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                productController.listenToProducts();
                productController.listenToCategories();
              });
              _streamsStarted = true;
            }
            return const HomeScreen();
          }
        } else {
          // Logged out
          if (_streamsStarted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              productController.stopListening();
              favoriteController.stopListening();
              cartController.stopListening();
              orderController.stopListening();
              adminController.stopListening();
            });
            _streamsStarted = false;
          }
          _profileLoadingTriggered = false;

          return const LoginScreen();
        }
      },
    );
  }
}
