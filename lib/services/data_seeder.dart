import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedAllData() async {
    try {
      await seedLessons();
      await seedQuizzes();
      developer.log('✅ All data seeded successfully!');
    } catch (e) {
      developer.log('❌ Error seeding data: $e');
      rethrow;
    }
  }

  Future<void> seedLessons() async {
    try {
      // Check if lessons already exist
      final snapshot = await _firestore.collection('lessons').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        developer.log('⚠️ Lessons already exist. Skipping...');
        return;
      }

      // Load JSON file
      final String jsonString =
          await rootBundle.loadString('assets/data/lessons.json');
      final List<dynamic> lessonsData = json.decode(jsonString);

      // Upload each lesson to Firestore
      final batch = _firestore.batch();
      for (var lessonData in lessonsData) {
        final docRef = _firestore.collection('lessons').doc();
        final data = Map<String, dynamic>.from(lessonData as Map);
        data['createdAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data);
      }

      await batch.commit();
      developer.log('✅ Seeded ${lessonsData.length} lessons');
    } catch (e) {
      developer.log('❌ Error seeding lessons: $e');
      rethrow;
    }
  }

  Future<void> seedQuizzes() async {
    try {
      // Check if quizzes already exist
      final snapshot = await _firestore.collection('quizzes').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        developer.log('⚠️ Quizzes already exist. Skipping...');
        return;
      }

      // Load JSON file
      final String jsonString =
          await rootBundle.loadString('assets/data/quizzes.json');
      final List<dynamic> quizzesData = json.decode(jsonString);

      // Upload each quiz to Firestore
      final batch = _firestore.batch();
      for (var quizData in quizzesData) {
        final docRef = _firestore.collection('quizzes').doc();
        final data = Map<String, dynamic>.from(quizData as Map);
        data['createdAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data);
      }

      await batch.commit();
      developer.log('✅ Seeded ${quizzesData.length} quizzes');
    } catch (e) {
      developer.log('❌ Error seeding quizzes: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      await _clearCollection('lessons');
      await _clearCollection('quizzes');
      developer.log('✅ All data cleared successfully!');
    } catch (e) {
      developer.log('❌ Error clearing data: $e');
      rethrow;
    }
  }

  Future<void> _clearCollection(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    developer.log('✅ Cleared $collectionName collection');
  }

  Future<void> reseedAllData() async {
    try {
      await clearAllData();
      await seedAllData();
      developer.log('✅ Data reseeded successfully!');
    } catch (e) {
      developer.log('❌ Error reseeding data: $e');
      rethrow;
    }
  }
}
