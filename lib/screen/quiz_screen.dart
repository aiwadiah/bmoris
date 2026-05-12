import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import 'quiz_history_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedAnswer;
  bool _hasAnswered = false;
  bool _hasStarted = false;
  bool _hasProcessedCompletion = false;
  bool _isProcessingCompletion = false;
  int? _awardedXpDelta;
  bool _xpAwardFailed = false;

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Quiz Challenge',
          style: GoogleFonts.poppins(
            color: const Color(0xFF00897B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00897B),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizHistoryScreen(),
                ),
              );
            },
          ),
        ],
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

          if (!_hasStarted) {
            return _buildStartPage(quizProvider);
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
          Image.asset('assets/dodo.png', width: 100, height: 100),
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
          value:
              (quizProvider.currentQuizIndex + 1) / quizProvider.totalQuestions,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        quiz.difficulty,
                      ).withValues(alpha: 0.1),
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48), // Moved up
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: ElevatedButton(
              onPressed: () {
                quizProvider.nextQuestion();
                setState(() {
                  _selectedAnswer = null;
                  _hasAnswered = false;
                  if (quizProvider.isCompleted) {
                    _hasProcessedCompletion = false;
                    _isProcessingCompletion = false;
                    _awardedXpDelta = null;
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                minimumSize: const Size(
                  double.infinity,
                  56,
                ), // Increased height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Reduced curve
                ),
                elevation: 0,
              ),
              child: Text(
                quizProvider.currentQuizIndex < quizProvider.totalQuestions - 1
                    ? 'Next Question'
                    : 'See Results',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
        onTap:
            _hasAnswered
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

  Future<void> _processQuizCompletionAward(
    QuizProvider quizProvider,
    int completedDifficulty,
  ) async {
    if (_hasProcessedCompletion || _isProcessingCompletion) return;

    setState(() {
      _isProcessingCompletion = true;
      _xpAwardFailed = false;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final xpDelta = await authProvider.awardQuizCompletionXp(
        difficulty: completedDifficulty,
        score: quizProvider.score,
        correctAnswers: quizProvider.correctAnswers,
        totalQuestions: quizProvider.totalQuestions,
      );

      if (!mounted) return;
      setState(() {
        _awardedXpDelta = xpDelta;
        _xpAwardFailed = false;
        _hasProcessedCompletion = true;
        _isProcessingCompletion = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _awardedXpDelta = null;
        _xpAwardFailed = true;
        _hasProcessedCompletion = true;
        _isProcessingCompletion = false;
      });
    }
  }

  Widget _buildResultScreen(QuizProvider quizProvider) {
    final percentage = quizProvider.accuracyPercentage;
    final isPassed = percentage >= 70;
    final completedDifficulty =
        quizProvider.quizzes.isNotEmpty
            ? quizProvider.quizzes.first.difficulty
            : quizProvider.currentDifficulty;
    final recommendedDifficulty = quizProvider.getRecommendedDifficulty();
    final hasNextLevel = recommendedDifficulty > completedDifficulty;

    if (!_hasProcessedCompletion && !_isProcessingCompletion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _processQuizCompletionAward(quizProvider, completedDifficulty);
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Dodo Mascot Reaction
          Image.asset(
            isPassed ? 'assets/bmorisbirdgreat.png' : 'assets/dodoSad.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Great Job!' : 'Keep Practicing!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
              color: (isPassed ? Colors.green : Colors.orange).withValues(
                alpha: 0.1,
              ),
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
                    Flexible(
                      child: Text(
                        _buildAwardedXpLabel(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed:
                    _isProcessingCompletion
                        ? null
                        : () {
                          setState(() {
                            _selectedAnswer = null;
                            _hasAnswered = false;
                            _hasStarted = false;
                            _hasProcessedCompletion = false;
                            _isProcessingCompletion = false;
                            _awardedXpDelta = null;
                            _xpAwardFailed = false;
                          });
                          quizProvider.reset();
                          quizProvider.loadAdaptiveQuizzes(completedDifficulty);
                        },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  foregroundColor: const Color(0xFF00897B),
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
              if (hasNextLevel) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed:
                      _hasProcessedCompletion
                          ? () {
                            setState(() {
                              _selectedAnswer = null;
                              _hasAnswered = false;
                              _hasStarted = true;
                              _hasProcessedCompletion = false;
                              _isProcessingCompletion = false;
                              _awardedXpDelta = null;
                              _xpAwardFailed = false;
                            });
                            quizProvider.loadAdaptiveQuizzes(
                              recommendedDifficulty,
                            );
                          }
                          : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: Text(
                    'Next Level',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:
                    _isProcessingCompletion
                        ? null
                        : () {
                          setState(() {
                            _selectedAnswer = null;
                            _hasAnswered = false;
                            _hasStarted = false;
                            _hasProcessedCompletion = false;
                            _isProcessingCompletion = false;
                            _awardedXpDelta = null;
                            _xpAwardFailed = false;
                          });
                          quizProvider.reset();
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Finish',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildAwardedXpLabel() {
    if (_isProcessingCompletion) {
      return 'Updating XP...';
    }

    if (_xpAwardFailed) {
      return 'XP update failed. Please try again.';
    }

    if (_awardedXpDelta == null) {
      return 'Updating XP...';
    }

    if (_awardedXpDelta! > 0) {
      return '+$_awardedXpDelta XP';
    }

    return 'No new XP — best score already higher/equal';
  }

  Widget _buildStartPage(QuizProvider quizProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/bmorisbirdquiz.png',
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Ready for a Challenge?',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00695C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Test your Malay language skills with our adaptive quiz. The questions will get harder as you improve!',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasStarted = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start Quiz',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${quizProvider.quizzes.length} Questions • Adaptive Difficulty',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
