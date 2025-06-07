import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/Container/Repositories/auth_repo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void login(BuildContext context) async {
    setState(() => isLoading = true);
    try {
      // await ref
      //     .read(globalAuthRepoProvider)
      //     //.loginWithEmailPassword(
      //       email: emailController.text.trim(),
      //       password: passwordController.text.trim(),
      //       context: context,
      //     );
    } catch (e) {
      // handled in auth_repo
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Bar in blue
        foregroundColor: Colors.white,
        title: const Text("Login", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.black),
                        prefixIcon: Icon(Icons.email, color: Colors.blue),
                      ),
                      validator:
                          (val) =>
                              val == null || !val.contains('@')
                                  ? "Enter valid email"
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.black),
                        prefixIcon: Icon(Icons.lock, color: Colors.blue),
                      ),
                      validator:
                          (val) =>
                              val == null || val.length < 6
                                  ? "Password must be 6+ chars"
                                  : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : () => login(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, //[700], // Button in yellow
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                          "Login",
                          style: TextStyle(color: Colors.black),
                        ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(globalAuthRepoProvider),
                // .signInWithGoogle(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue, //[700], // Google Button in yellow
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.blue, width: 1),
                ),
                icon: const Icon(Icons.login, color: Colors.blue),
                label: const Text(
                  "Login with Google",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
