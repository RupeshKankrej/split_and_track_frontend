import 'package:expense_tracker/utils/api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart'; // Ensure this exists or create dummy

class LoginScreen extends StatefulWidget {
  final String baseUrl;
  const LoginScreen({super.key, required this.baseUrl});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await Dio().post(
        '${widget.baseUrl}/auth/login',
        data: {
          "email": _emailController.text.trim(),
          "password": _passController.text,
        },
      );

      if (response.statusCode == 200 && mounted) {
        final userData = response.data;

        final prefs = await SharedPreferences.getInstance();

        final userId = response.data['id'];
        final userName = response.data['name'];

        await prefs.setString('token', userData['token']);
        await prefs.setInt('userId', userId);
        await prefs.setString('userName', userName);

        try {
          FirebaseMessaging messaging = FirebaseMessaging.instance;

          await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          String? token = await messaging.getToken();

          if (token != null) {
            print("Registering Token on Login: $token");

            // Send to Backend
            await ApiClient.create(widget.baseUrl).post(
              "${widget.baseUrl}/notifications/register-device",
              data: {"userId": userId, "token": token},
            );
            print("Token registered successfully");
          }
        } catch (e) {
          print("Failed to register token during login: $e");
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              baseUrl: widget.baseUrl,
              userId: userData['id'],
              userName: userData['name'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Icon Color
              Icon(Icons.wallet, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),

              Text(
                "Welcome Back",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to manage your expenses",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _login,
                        child: const Text(
                          "Sign In",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(baseUrl: widget.baseUrl),
                    ),
                  );
                },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
