import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 SEND TO FOLLOWERS
  Future<void> sendToFollowers({
    required String userId,
    required String title,
    required String body,
  }) async {
    final snapshot = await _firestore
        .collection('followers')
        .where('userId', isEqualTo: userId)
        .get();

    print("USER ID: $userId");
    print("FOLLOWERS FOUND: ${snapshot.docs.length}");

    for (var doc in snapshot.docs) {
      final followerId = doc['followerId'];

      print("SEND TO: $followerId");

      await _firestore.collection('notifications').add({
        'toUserId': followerId,
        'fromUserId': userId,
        'title': title,
        'body': body,
        'type': 'activity',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 🔥 FOLLOW USER
  Future<void> followUser({
    required String myId,
    required String targetUserId,
  }) async {
    await _firestore.collection('followers').add({
      'userId': targetUserId,
      'followerId': myId,
    });
  }

  // 🔥 DIRECT TEST (UNTUK DEBUG)
  Future<void> sendDirect({
    required String toUserId,
  }) async {
    await _firestore.collection('notifications').add({
      'toUserId': toUserId,
      'fromUserId': 'system',
      'title': 'TEST NOTI',
      'body': 'Notification working 🔥',
      'type': 'test',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}