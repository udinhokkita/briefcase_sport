import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'signup_page.dart';
import 'role_gate.dart';
import 'auth_service.dart'; // 🔥 TAMBAH

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthService authService = AuthService(); // 🔥 TAMBAH

  // ================= EMAIL LOGIN =================
  Future<void> loginEmail() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showMsg("Sila isi semua maklumat");
      return;
    }

    setState(() => isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 🔥 AUTO CREATE USER FIRESTORE
      await authService.createUserIfNotExist(cred.user!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleGate(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      showMsg(e.message ?? "Login gagal");
    } catch (e) {
      showMsg("Login gagal");
    }

    setState(() => isLoading = false);
  }

  // ================= GOOGLE LOGIN =================
  Future<void> loginWithGoogle() async {
    setState(() => isGoogleLoading = true);

    try {
      if (kIsWeb) {
        // 🌐 WEB
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        final cred =
        await FirebaseAuth.instance.signInWithPopup(googleProvider);

        // 🔥 AUTO CREATE USER
        await authService.createUserIfNotExist(cred.user!);
      } else {
        // 📱 MOBILE
        final user = await _googleSignIn.signIn();

        if (user == null) {
          setState(() => isGoogleLoading = false);
          return;
        }

        final auth = await user.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );

        final cred = await FirebaseAuth.instance
            .signInWithCredential(credential);

        // 🔥 AUTO CREATE USER
        await authService.createUserIfNotExist(cred.user!);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleGate(),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      showMsg("Google login gagal");
    }

    setState(() => isGoogleLoading = false);
  }

  // ================= SNACKBAR =================
  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F1F),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events,
                    size: 55, color: Color(0xFF22C55E)),

                const SizedBox(height: 12),

                const Text(
                  "Welcome Back",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),

                const SizedBox(height: 25),

                // EMAIL
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputStyle("Email"),
                ),

                const SizedBox(height: 15),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputStyle("Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : loginEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      "Login",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // GOOGLE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                    isGoogleLoading ? null : loginWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side:
                        const BorderSide(color: Colors.white24),
                      ),
                    ),
                    child: isGoogleLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                      "Sign in with Google",
                      style:
                      TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // SIGNUP
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUpPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Belum ada akaun? Daftar",
                    style: TextStyle(color: Color(0xFF22C55E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= INPUT STYLE =================
  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF111827),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }
}