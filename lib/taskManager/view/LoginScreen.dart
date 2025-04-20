import 'package:flutter/material.dart';
import '../db/UserDatabase.dart';
import '../model/User.dart';
import 'package:baitapcuoiky/main.dart'; // Import main.dart để sử dụng ThemeSwitchingWidget

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final users = await UserDatabase.instance.getAllUsers();
        final user = users.firstWhere(
              (user) =>
          user.username == _usernameController.text &&
              user.password == _passwordController.text,
          orElse: () => User(
            id: '',
            username: '',
            password: '',
            email: '',
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          ),
        );

        if (user.id.isNotEmpty) {
          final updatedUser = user.copyWith(lastActive: DateTime.now());
          await UserDatabase.instance.updateUser(updatedUser);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/task_list', arguments: updatedUser);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tên đăng nhập hoặc mật khẩu không đúng')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã có lỗi xảy ra: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy ThemeSwitchingWidget để truy cập isDarkMode và toggleTheme
    final themeSwitching = ThemeSwitchingWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        actions: [
          IconButton(
            icon: Icon(themeSwitching.isDarkMode ? Icons.brightness_7 : Icons.brightness_4),
            onPressed: themeSwitching.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Đăng nhập'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Chưa có tài khoản? Đăng ký ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}