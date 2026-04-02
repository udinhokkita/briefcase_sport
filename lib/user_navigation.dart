import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'schedule_page.dart';
import 'tournament_list_page.dart';
import 'search_user_page.dart';
import 'notification_page.dart';
import 'role_gate.dart';

class UserNavigation extends StatefulWidget {
  const UserNavigation({super.key});

  @override
  State<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends State<UserNavigation> {
  int currentIndex = 0;

  late final List<Widget> pages;

  Stream<DocumentSnapshot>? userStream;

  StreamSubscription? notificationSub;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    pages = [
      TournamentListPage(isAdmin: false),
      SchedulePage(),
      const SearchUserPage(),
      const NotificationPage(),
      ProfilePage(
        userId: uid,
        currentUserId: uid,
      ),
    ];

    userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();

    listenNotification();
  }

  // 🔥 LISTEN NOTIFICATION
  void listenNotification() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    notificationSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();

          if (data != null) {
            showPopup(data);
          }
        }
      }
    });
  }

  // 🔥 POPUP FIX WEB
  void showPopup(Map<String, dynamic> data) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final title = data['title'] ?? '';
    final body = data['body'] ?? '';

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _TopNotification(
          title: title,
          body: body,
          onDismiss: () {
            overlayEntry.remove();
          },
        );
      },
    );

    // 🔥 FIX WEB DELAY
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlay.insert(overlayEntry);
    });
  }

  @override
  void dispose() {
    notificationSub?.cancel();
    super.dispose();
  }

  // 🔴 BADGE
  Widget _buildNotificationIcon() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications),

            if (count > 0)
              Positioned(
                right: -6,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'] ?? 'user';

        if (role == 'admin') {
          return const RoleGate();
        }

        return Scaffold(
          body: pages[currentIndex],

          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1F2937)),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: const Color(0xFF0B1220),
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,

              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },

              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events),
                  label: 'Tournament',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.schedule),
                  label: 'Schedule',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: _buildNotificationIcon(),
                  label: 'Noti',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🔥 POPUP ATAS
class _TopNotification extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _TopNotification({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      controller.reverse().then((_) {
        widget.onDismiss();
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: SlideTransition(
        position: slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.body,
                        style: const TextStyle(color: Colors.white70),
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