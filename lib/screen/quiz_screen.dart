import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedAnswer;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quizProvider.loadAdaptiveQuizzes(quizProvider.currentDifficulty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, _) {
          if (quizProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (quizProvider.quizzes.isEmpty) {
            return _buildEmptyState();
          }

          if (quizProvider.isCompleted) {
            return _buildResultScreen(quizProvider);
          }

          return _buildQuizContent(quizProvider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/dodo.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 16),
          const Text(
            'No quizzes available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete some lessons first',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(QuizProvider quizProvider) {
    final quiz = quizProvider.currentQuiz!;

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: (quizProvider.currentQuizIndex + 1) / quizProvider.totalQuestions,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question Counter
                Text(
                  'Question ${quizProvider.currentQuizIndex + 1} of ${quizProvider.totalQuestions}',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Difficulty Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(quiz.difficulty).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level ${quiz.difficulty}',
                      style: TextStyle(
                        color: _getDifficultyColor(quiz.difficulty),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Question
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        quiz.questionMalay,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00796B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quiz.question,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Options
                ...List.generate(quiz.options.length, (index) {
                  return _buildOptionButton(quiz, index, quizProvider);
                }),
              ],
            ),
          ),
        ),

        // Next Button
        if (_hasAnswered)
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                quizProvider.nextQuestion();
                setState(() {
                  _selectedAnswer = null;
                  _hasAnswered = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                quizProvider.currentQuizIndex < quizProvider.totalQuestions - 1
                    ? 'Next Question'
                    : 'See Results',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(quiz, int index, QuizProvider quizProvider) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black;

    if (_hasAnswered) {
      if (index == quiz.correctIndex) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
      } else if (index == _selectedAnswer && index != quiz.correctIndex) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
      }
    } else if (index == _selectedAnswer) {
      backgroundColor = const Color(0xFF00796B).withValues(alpha: 0.1);
      borderColor = const Color(0xFF00796B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _hasAnswered
            ? null
            : () {
                setState(() {
                  _selectedAnswer = index;
                });
                _submitAnswer(quizProvider, index);
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quiz.options[index],
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              ),
              if (_hasAnswered && index == quiz.correctIndex)
                const Icon(Icons.check_circle, color: Colors.green),
              if (_hasAnswered &&
                  index == _selectedAnswer &&
                  index != quiz.correctIndex)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  void _submitAnswer(QuizProvider quizProvider, int selectedIndex) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    quizProvider.answerQuestion(selectedIndex, authProvider.user?.uid ?? '');

    setState(() {
      _hasAnswered = true;
    });
  }

  Widget _buildResultScreen(QuizProvider quizProvider) {
    final percentage = quizProvider.accuracyPercentage;
    final isPassed = percentage >= 70;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Dodo Mascot Reaction
          Image.asset(
            isPassed ? 'assets/dodoHappy.png' : 'assets/dodoSad.png',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Great Job!' : 'Keep Practicing!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPassed
                ? 'You\'ve mastered this level!'
                : 'Don\'t give up, try again!',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isPassed ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${quizProvider.correctAnswers} of ${quizProvider.totalQuestions} correct',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '+${quizProvider.score} XP',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recommended Next Level
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recommended difficulty: Level ${quizProvider.getRecommendedDifficulty()}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    quizProvider.reset();
                    quizProvider.loadAdaptiveQuizzes(quizProvider.currentDifficulty);
                  },
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.addXp(quizProvider.score);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                  ),
                  child: const Text('Finish',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
