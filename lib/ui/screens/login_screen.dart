import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../state/app_state.dart';
import '../home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    
    bool success;
    if (_isLogin) {
      success = await _authService.login(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
      );
    } else {
      success = await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(), 
        _passwordController.text.trim(),
      );
    }

    if (success && mounted) {
      // 1. Pull cloud data from PostgreSQL and push local SQLite data up
      await CloudSyncService().pullFromCloud();
      await CloudSyncService().pushToCloud();

      // 2. Reload state providers so UI reflects synced data
      if (mounted) {
        context.read<NotebooksState>().load();
        context.read<MyWidgetsState>().load();
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Login failed' : 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.widgets_rounded, size: 80, color: Colors.indigo),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Need an account? Sign up' : 'Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}