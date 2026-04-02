import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'role_gate.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  final AuthService authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ================= SIGNUP EMAIL =================
  Future<void> doSignUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      showMsg("Sila lengkapkan semua maklumat");
      return;
    }

    if (password != confirm) {
      showMsg("Password tidak sama");
      return;
    }

    if (password.length < 6) {
      showMsg("Password minimum 6 aksara");
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await authService.signUp(name, email, password);

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': name,
          'email': email,
          'role': 'user',
          'onboardingDone': false,
        });
      }

      if (mounted) {
        showMsg("Akaun berjaya");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      showMsg("Signup gagal");
    }

    setState(() => isLoading = false);
  }

  // ================= GOOGLE SIGNUP =================
  Future<void> signUpWithGoogle() async {
    setState(() => isGoogleLoading = true);

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          setState(() => isGoogleLoading = false);
          return;
        }

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
      }

      final user = userCredential.user!;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'role': 'user',
          'onboardingDone': false,
        });
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleGate()),
              (route) => false,
        );
      }
    } catch (e) {
      showMsg("Google signup gagal");
    }

    setState(() => isGoogleLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

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
                const Icon(Icons.person_add,
                    size: 55, color: Color(0xFF22C55E)),

                const SizedBox(height: 12),

                const Text(
                  "Create Account",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),

                const SizedBox(height: 25),

                // NAME
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputStyle("Name"),
                ),

                const SizedBox(height: 15),

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

                const SizedBox(height: 15),

                // CONFIRM
                TextField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputStyle("Confirm Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // SIGNUP BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : doSignUp,
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
                      "Sign Up",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // GOOGLE
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                    isGoogleLoading ? null : signUpWithGoogle,
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
                      "Sign up with Google",
                      style:
                      TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // LOGIN LINK
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    "Dah ada akaun? Login",
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