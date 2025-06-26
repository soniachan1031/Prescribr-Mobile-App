import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../main.dart'; // For navigatorKey
import 'register_screen.dart';
import 'forget_password_screen.dart';
import 'home_screen.dart'; // Re-added for direct navigation
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    print('🔵 LOGIN METHOD STARTED');
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Simple login attempt
        print('🔵 Attempting Firebase login with email: $email');
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        if (userCredential.user != null) {
          print('🔵 Login successful for user: ${userCredential.user?.email}');

          // Force user refresh to get latest data
          await userCredential.user!.reload();
          print('🔵 User data reloaded');

          // Wait for auth state to propagate
          await FirebaseAuth.instance.authStateChanges().first;
          print('🔵 Auth state changes propagated');

          // Critical: Ensure login state is fully processed before UI updates
          if (!mounted) return;
          _showSafeSnackBar('Login successful!');

          print(
              '🔵 NAVIGATION: Immediately navigating to HomeScreen with rootNavigator');
          // SIMPLIFIED APPROACH: Navigate immediately using root navigator
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const HomeScreen(initialIndex: 0)),
            (route) => false, // Remove all previous routes
          );
        } else {
          print('🔵 ERROR: User is null after login');
          if (!mounted) return;
          _showSafeSnackBar("Login failed. User not found.");
        }
      } on FirebaseAuthException catch (e) {
        print('🔵 Firebase Auth Error: ${e.message}');
        if (!mounted) return;
        _showSafeSnackBar(e.message ?? 'Login failed');
      } catch (e) {
        print('🔵 Unexpected Error: $e');
        if (!mounted) return;
        _showSafeSnackBar('An unexpected error occurred.');
      } finally {
        // Always reset loading state if mounted
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('🔵 Form validation failed');
    }
  }

  // Helper method to safely show SnackBar using global navigator key
  void _showSafeSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      print('Cannot show SnackBar: No valid context available');
    }
  }

  // We're now letting AuthStateHandler manage navigation automatically

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        elevation: 0,
        backgroundColor: AppTheme.whiteColor,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40.0),

              // Title
              Center(
                child: Text(
                  "Welcome Back",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ),
              const SizedBox(height: 10.0),
              Center(
                child: Text(
                  "Login to your account",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
              const SizedBox(height: 40.0),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 10.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 10.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30.0),

              // Login Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        "Login Now",
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
              const SizedBox(height: 20.0),
              //Forget password
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    "Forget password? Reset now",
                    style:
                        TextStyle(fontSize: 14.0, color: AppTheme.blackColor),
                  ),
                ),
              ),
              // Navigate to Register
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Register now",
                    style:
                        TextStyle(fontSize: 14.0, color: AppTheme.blackColor),
                  ),
                ),
              ),

              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
