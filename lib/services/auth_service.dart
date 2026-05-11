import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;
    return await getUserById(currentUser!.uid);
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: 'user',
          xp: 0,
          streak: 0,
          badges: [],
          currentLevel: 1,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(user.toMap());
        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signUpAsAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: 'admin',
          xp: 0,
          streak: 0,
          badges: [],
          currentLevel: 1,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(user.toMap());
        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        });
        return await getUserById(credential.user!.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateStreak(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      final lastLogin = DateTime.parse(data['lastLoginAt']);
      final now = DateTime.now();
      final difference = now.difference(lastLogin).inDays;

      int newStreak = data['streak'] ?? 0;
      if (difference == 1) {
        newStreak++;
      } else if (difference > 1) {
        newStreak = 1;
      }

      await _firestore.collection('users').doc(uid).update({
        'streak': newStreak,
        'lastLoginAt': now.toIso8601String(),
      });
    }
  }

  Future<void> addXp(String uid, int xp) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        return;
      }

      final data = userDoc.data()!;
      transaction.update(userRef, {
        'xp': FieldValue.increment(xp),
      });

      if ((data['role'] ?? 'user') != 'user') {
        return;
      }

      final weekId = FirestoreService.getWeekId();
      final weeklyRef = _firestoreService
          .firestore
          .collection('weekly_leaderboards')
          .doc(weekId)
          .collection('entries')
          .doc(uid);
      final weeklyDoc = await transaction.get(weeklyRef);
      final currentWeeklyXp = weeklyDoc.exists
          ? ((weeklyDoc.data()?['xp'] ?? 0) as int)
          : 0;

      transaction.set(
        weeklyRef,
        {
          'userId': uid,
          'name': data['name'] ?? '',
          'photoUrl': data['photoUrl'],
          'xp': currentWeeklyXp + xp,
          'streak': data['streak'] ?? 0,
          'currentLevel': data['currentLevel'] ?? 1,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> addBadge(String uid, String badge) async {
    await _firestore.collection('users').doc(uid).update({
      'badges': FieldValue.arrayUnion([badge]),
    });
  }

  Future<void> updateDailyGoal(String uid, {int? count, String? date, int? target}) async {
    final updates = <String, dynamic>{};
    if (count != null) updates['dailyActivitiesCount'] = count;
    if (date != null) updates['lastActivityDate'] = date;
    if (target != null) updates['dailyGoalTarget'] = target;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> incrementActivityCount(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'dailyActivitiesCount': FieldValue.increment(1),
      'lastActivityDate': DateTime.now().toIso8601String().split('T')[0],
    });
  }
}
