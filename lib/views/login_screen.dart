import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load remembered email if exists
  Future<void> _loadRememberedEmail() async {
    final authController = context.read<AuthController>();
    final email = await authController.loadRememberedEmail();
    if (email != null) {
      setState(() {
        _emailController.text = email;
        _rememberMe = true;
      });
    }
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = context.read<AuthController>();

    // Handle Remember Me
    if (_rememberMe) {
      await authController.saveRememberedEmail(_emailController.text);
    } else {
      await authController.clearRememberedEmail();
    }

    final success = await authController.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success && authController.errorMessage != null) {
      _showErrorSnackBar(authController.errorMessage!);
    }
  }

  /// Handle Google sign in
  Future<void> _handleGoogleSignIn() async {
    final authController = context.read<AuthController>();
    final success = await authController.signInWithGoogle();

    if (!mounted) return;

    if (!success && authController.errorMessage != null) {
      _showErrorSnackBar(authController.errorMessage!);
    }
  }

  /// Handle guest sign in
  Future<void> _handleGuestSignIn() async {
    final authController = context.read<AuthController>();
    final success = await authController.signInAnonymously();

    if (!mounted) return;

    if (!success && authController.errorMessage != null) {
      _showErrorSnackBar(authController.errorMessage!);
    }
  }

  /// Handle forgot password
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    // Validate email
    final emailError = Validators.email(email);
    if (emailError != null) {
      _showErrorSnackBar(emailError);
      return;
    }

    final authController = context.read<AuthController>();

    if (!authController.canSendPasswordReset) {
      _showErrorSnackBar(
        'Please wait ${authController.forgotPasswordCooldownSeconds}s before trying again',
      );
      return;
    }

    final success = await authController.sendPasswordResetEmail(email);

    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('If an account exists, a reset email has been sent');
    } else if (authController.errorMessage != null) {
      _showErrorSnackBar(authController.errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.brightness_2_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      Switch(
                        value: themeController.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeController.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // App title
                  Text(
                    'StyleHub',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: Validators.email,
                    enabled: !authController.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: Validators.password,
                    enabled: !authController.isLoading,
                  ),
                  const SizedBox(height: 8),

                  // Remember Me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: authController.isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                          ),
                          Text(
                            'Remember Me',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: authController.isLoading
                            ? null
                            : _handleForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  FilledButton(
                    onPressed: authController.isLoading ? null : _handleLogin,
                    child: authController.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign In button
                  OutlinedButton.icon(
                    onPressed: authController.isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),

                  // Guest button
                  OutlinedButton.icon(
                    onPressed: authController.isLoading ? null : _handleGuestSignIn,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Browse as Guest'),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: authController.isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
