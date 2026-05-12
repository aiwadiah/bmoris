import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserById(firebaseUser.uid);
        if (_user != null) {
          await _checkAndResetDailyGoal();
        }
        notifyListeners();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpAsAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUpAsAdmin(
        email: email,
        password: password,
        name: name,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_authService.currentUser != null) {
      _user = await _authService.getUserById(_authService.currentUser!.uid);
      if (_user != null) {
        await _checkAndResetDailyGoal();
      }
      notifyListeners();
    }
  }

  Future<void> _checkAndResetDailyGoal() async {
    if (_user == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_user!.lastActivityDate != today) {
      await _authService.updateDailyGoal(_user!.uid, count: 0, date: today);
      _user = _user!.copyWith(dailyActivitiesCount: 0, lastActivityDate: today);
    }
  }

  Future<void> incrementActivityCount() async {
    if (_user != null) {
      await _authService.incrementActivityCount(_user!.uid);
      await refreshUser();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    if (_user != null) {
      await _authService.updateUserProfile(
        uid: _user!.uid,
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
      );
      await refreshUser();
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    try {
      await _authService.updateEmail(newEmail);
      return true;
    } catch (e) {
      _error = 'Failed to update email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = 'Failed to send password reset email.';
      notifyListeners();
      return false;
    }
  }

  Future<void> addXp(int xp) async {
    if (_user != null) {
      final oldXp = _user!.xp;
      await _authService.addXp(_user!.uid, xp);
      await refreshUser();

      // Check and award badges based on new XP
      if (_user != null) {
        await _checkAndAwardBadges(oldXp, _user!.xp);
      }
    }
  }

  Future<int> awardQuizCompletionXp({
    required int difficulty,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    if (_user == null) return 0;

    final oldXp = _user!.xp;
    final xpDelta = await _authService.awardQuizLevelBestScoreXp(
      uid: _user!.uid,
      difficulty: difficulty,
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
    );

    await _authService.incrementActivityCount(_user!.uid);
    await refreshUser();

    if (xpDelta > 0 && _user != null) {
      await _checkAndAwardBadges(oldXp, _user!.xp);
    }

    return xpDelta;
  }

  Future<void> _checkAndAwardBadges(int oldXp, int newXp) async {
    if (_user == null) return;

    final badges = <String>[];

    // XP Milestones
    if (oldXp < 100 &&
        newXp >= 100 &&
        !_user!.badges.contains('First 100 XP')) {
      badges.add('First 100 XP');
    }
    if (oldXp < 500 && newXp >= 500 && !_user!.badges.contains('XP Master')) {
      badges.add('XP Master');
    }
    if (oldXp < 1000 && newXp >= 1000 && !_user!.badges.contains('XP Legend')) {
      badges.add('XP Legend');
    }
    if (oldXp < 2000 &&
        newXp >= 2000 &&
        !_user!.badges.contains('XP Champion')) {
      badges.add('XP Champion');
    }

    // Level Milestones
    if (_user!.currentLevel >= 5 && !_user!.badges.contains('Level 5')) {
      badges.add('Level 5');
    }
    if (_user!.currentLevel >= 10 && !_user!.badges.contains('Level 10')) {
      badges.add('Level 10');
    }
    if (_user!.currentLevel >= 20 && !_user!.badges.contains('Level 20')) {
      badges.add('Level 20');
    }

    // Streak Milestones
    if (_user!.streak >= 7 && !_user!.badges.contains('Week Warrior')) {
      badges.add('Week Warrior');
    }
    if (_user!.streak >= 30 && !_user!.badges.contains('Month Master')) {
      badges.add('Month Master');
    }

    // Award all earned badges
    for (final badge in badges) {
      await addBadge(badge);
    }
  }

  Future<void> addBadge(String badge) async {
    if (_user != null) {
      await _authService.addBadge(_user!.uid, badge);
      await refreshUser();
    }
  }

  // Check all badges and award any missing ones based on current stats
  Future<void> checkAndAwardAllEligibleBadges() async {
    if (_user == null) return;

    final badges = <String>[];

    // XP Milestones
    if (_user!.xp >= 100 && !_user!.badges.contains('First 100 XP')) {
      badges.add('First 100 XP');
    }
    if (_user!.xp >= 500 && !_user!.badges.contains('XP Master')) {
      badges.add('XP Master');
    }
    if (_user!.xp >= 1000 && !_user!.badges.contains('XP Legend')) {
      badges.add('XP Legend');
    }
    if (_user!.xp >= 2000 && !_user!.badges.contains('XP Champion')) {
      badges.add('XP Champion');
    }

    // Level Milestones
    if (_user!.currentLevel >= 5 && !_user!.badges.contains('Level 5')) {
      badges.add('Level 5');
    }
    if (_user!.currentLevel >= 10 && !_user!.badges.contains('Level 10')) {
      badges.add('Level 10');
    }
    if (_user!.currentLevel >= 20 && !_user!.badges.contains('Level 20')) {
      badges.add('Level 20');
    }

    // Streak Milestones
    if (_user!.streak >= 7 && !_user!.badges.contains('Week Warrior')) {
      badges.add('Week Warrior');
    }
    if (_user!.streak >= 30 && !_user!.badges.contains('Month Master')) {
      badges.add('Month Master');
    }

    // Award all earned badges
    for (final badge in badges) {
      await addBadge(badge);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
