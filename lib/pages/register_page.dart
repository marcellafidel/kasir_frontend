
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color maroon = Color(0xFF800020);
  static const String baseUrl = 'http://192.168.18.52:3000/api/v1';

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storeController = TextEditingController();

  String businessType = 'Grocery';
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    storeController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final storeName = storeController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        storeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi')),
      );
      return;
    }

    if (password.length < 8 || password.length > 72) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus 8–72 karakter'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'storeName': storeName,
              'businessType': businessType,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! Silakan login.'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Pendaftaran gagal'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak bisa terhubung ke server. Periksa koneksi Wi-Fi.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: const Color(0xFFFAF8F8),
        foregroundColor: maroon,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.point_of_sale_rounded,
                    size: 64,
                    color: maroon,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Buat Akun Noma',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('Nama pemilik'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: inputDecoration(
                      'Masukkan nama',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Email'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecoration(
                      'Masukkan email',
                      Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: inputDecoration(
                      'Minimal 8 karakter',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nama toko atau usaha'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: storeController,
                    decoration: inputDecoration(
                      'Contoh: Toko Noma',
                      Icons.store_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Jenis usaha'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: businessType,
                    decoration: inputDecoration(
                      'Pilih jenis usaha',
                      Icons.category_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Grocery',
                        child: Text('Toko sembako'),
                      ),
                      DropdownMenuItem(
                        value: 'Cafe',
                        child: Text('Kafe / makanan'),
                      ),
                      DropdownMenuItem(
                        value: 'Laundry',
                        child: Text('Laundry'),
                      ),
                      DropdownMenuItem(
                        value: 'Retail',
                        child: Text('Toko retail'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Lainnya'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => businessType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: isLoading ? null : register,
                      style: FilledButton.styleFrom(
                        backgroundColor: maroon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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
