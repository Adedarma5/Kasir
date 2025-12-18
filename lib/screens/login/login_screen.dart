import 'package:flutter/material.dart';
import '../dashboard/menu_screen.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    setState(() => isLoading = true);
    final result = await AuthService.login(
      emailController.text,
      passwordController.text,
    );
    setState(() => isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 400;
    final cardWidth = isTablet ? 320.0 : size.width * 0.9;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 255, 255, 255),
              const Color.fromARGB(255, 255, 255, 255),
              Colors.brown[300]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 20,
              vertical: 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isTablet ? 120 : 100,
                  height: isTablet ? 120 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.brown[100]!,
                      width: 4,
                    ),
                  ),
                  child: Icon(
                    Icons.coffee_rounded,
                    size: isTablet ? 60 : 50,
                    color: Colors.brown[700],
                  ),
                ),
                
                const SizedBox(height: 30),

                Container(
                  width: cardWidth,
                  padding: EdgeInsets.all(isTablet ? 40 : 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 0,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Kasir Coffee",
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Silakan login untuk melanjutkan",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),

                      SizedBox(height: isTablet ? 40 : 32),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.brown[700]),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.brown[600],
                          ),
                          filled: true,
                          fillColor: Colors.brown[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.brown[200]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.brown[600]!,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isTablet ? 24 : 20),

                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.brown[700]),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.brown[600],
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.brown[600],
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          filled: true,
                          fillColor: Colors.brown[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.brown[200]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.brown[600]!,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),

                      SizedBox(height: isTablet ? 36 : 30),

                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 56 : 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[700],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.brown[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: Colors.brown.withOpacity(0.5),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: isTablet ? 28 : 24),

                      Text(
                        "© 2025 Kasir Coffee",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: isTablet ? 13 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
