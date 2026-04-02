import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 TAMBAH

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance; // 🔥 TAMBAH

  // LOGIN EMAIL
  Future<User?> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 🔥 AUTO CREATE USER
    await createUserIfNotExist(userCredential.user!);

    return userCredential.user;
  }

  // SIGN UP
  Future<User?> signUp(String name, String email, String password) async {
    final userCredential =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 🔥 AUTO CREATE USER
    await createUserIfNotExist(userCredential.user!);

    return userCredential.user;
  }

  // GOOGLE LOGIN
  Future<User?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
    await FirebaseAuth.instance.signInWithCredential(credential);

    // 🔥 AUTO CREATE USER
    await createUserIfNotExist(userCredential.user!);

    return userCredential.user;
  }

  // 🔥 AUTO CREATE USER FUNCTION
  Future<void> createUserIfNotExist(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      await _db.collection('users').doc(user.uid).set({
        'name': user.email?.split('@')[0] ?? 'User',
        'email': user.email,
        'role': 'user',
        'favoriteSports': [],
        'onboardingDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}