import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_question.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // NEW: Поток получения вопросов из коллекций Firestore (quiz_questions или с привязкой к лекции)
  Stream<List<QuizQuestion>> streamQuestionsForLesson(int lessonId) {
    return _db
        .collection('quiz_questions')
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <QuizQuestion>[];
      }
      return snapshot.docs.map((doc) => QuizQuestion.fromFirestore(doc)).toList();
    }).handleError((error) {
      return <QuizQuestion>[];
    });
  }
}