import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';
import 'login_page.dart';
import 'apply_admin_page.dart';
import 'followers_page.dart';
import 'following_page.dart';
import 'notification_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String currentUserId;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.currentUserId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isFollowing = false;

  bool get isOwner => widget.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    checkFollow();
  }

  Future<void> checkFollow() async {
    final res = await FirebaseFirestore.instance
        .collection('follows')
        .where('followerId', isEqualTo: widget.currentUserId)
        .where('followingId', isEqualTo: widget.userId)
        .get();

    if (!mounted) return;
    setState(() {
      isFollowing = res.docs.isNotEmpty;
    });
  }

  Future<void> followUser() async {
    final existing = await FirebaseFirestore.instance
        .collection('follows')
        .where('followerId', isEqualTo: widget.currentUserId)
        .where('followingId', isEqualTo: widget.userId)
        .get();

    if (existing.docs.isNotEmpty) {
      if (!mounted) return;
      setState(() => isFollowing = true);
      return;
    }

    await FirebaseFirestore.instance.collection('follows').add({
      'followerId': widget.currentUserId,
      'followingId': widget.userId,
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'followers': FieldValue.increment(1)});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .update({'following': FieldValue.increment(1)});

    // 🔥 ambil nama sebenar orang yang follow
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get();

    final currentUserData = currentUserDoc.data();
    final followerName = currentUserData?['name'] ?? 'Someone';
    final followerPhotoUrl = currentUserData?['photoUrl'];

    // 🔥 notification dengan nama follower
    await FirebaseFirestore.instance.collection('notifications').add({
      'toUserId': widget.userId,
      'fromUserId': widget.currentUserId,
      'fromUserName': followerName,
      'fromUserPhotoUrl': followerPhotoUrl,
      'title': 'New Follower 👀',
      'body': '$followerName started following you',
      'type': 'follow',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => isFollowing = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Followed successfully")),
    );
  }

  Future<void> unfollowUser() async {
    final res = await FirebaseFirestore.instance
        .collection('follows')
        .where('followerId', isEqualTo: widget.currentUserId)
        .where('followingId', isEqualTo: widget.userId)
        .get();

    for (var doc in res.docs) {
      await doc.reference.delete();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'followers': FieldValue.increment(-1)});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .update({'following': FieldValue.increment(-1)});

    if (!mounted) return;
    setState(() => isFollowing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Unfollowed")),
    );
  }

  Future<void> pickAndUploadImage() async {
    if (!isOwner) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final fileName =
        "${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child(fileName);

    if (kIsWeb) {
      Uint8List bytes = await pickedFile.readAsBytes();
      await ref.putData(bytes);
    } else {
      File file = File(pickedFile.path);
      await ref.putFile(file);
    }

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'photoUrl': url});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F1F),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(
                child: Text(
                  "User data not found",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final name = data['name'] ?? 'No Name';
            final email = data['email'] ?? 'No Email';
            final role = data['role'] ?? 'user';
            final followers = data['followers'] ?? 0;
            final following = data['following'] ?? 0;
            final photoUrl = data['photoUrl'];

            final sports = List<String>.from(data['favoriteSports'] ?? []);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1F2937)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.person, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "User Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PROFILE PIC
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: isOwner ? pickAndUploadImage : null,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.green,
                            child: CircleAvatar(
                              radius: 38,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? const Icon(Icons.person, size: 35)
                                  : null,
                            ),
                          ),
                        ),
                        if (isOwner)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role == 'admin' ? "Admin Account" : "User Account",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FOLLOWERS DESIGN
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF1F2937)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FollowingPage(userId: widget.userId),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Text(
                                  "$following",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Following",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 35,
                            color: Colors.white24,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FollowersPage(userId: widget.userId),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Text(
                                  "$followers",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Followers",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (!isOwner)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isFollowing ? unfollowUser : followUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            isFollowing ? Colors.red : Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            isFollowing ? "Unfollow" : "Follow",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ================= APPLY ADMIN (ADD ONLY) =================
                    if (isOwner && role != 'admin')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ApplyAdminPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Jadi Admin 🔥",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    buildCard(
                      icon: Icons.email,
                      title: "Email",
                      value: email,
                    ),

                    const SizedBox(height: 12),

                    buildCard(
                      icon: Icons.verified,
                      title: "Status",
                      value: role,
                    ),

                    const SizedBox(height: 25),

                    // FAVORITE SPORTS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF1F2937)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Favorite Sports",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: sports.isEmpty
                                ? [
                              const Text(
                                "Belum pilih sukan",
                                style:
                                TextStyle(color: Colors.white54),
                              )
                            ]
                                : sports.map((e) {
                              return Chip(
                                label: Text(e),
                                backgroundColor: Colors.green,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (isOwner)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  backgroundColor: const Color(0xFF0B1220),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 15),
                                        const Text(
                                          "Logout Account?",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "Are you sure you want to logout?",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                  Colors.grey[800],
                                                ),
                                                child: const Text("Cancel"),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);

                                                  await AuthService().logout();

                                                  if (context.mounted) {
                                                    Navigator.pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                        const LoginPage(),
                                                      ),
                                                          (route) => false,
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text("Logout"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );
  }
}