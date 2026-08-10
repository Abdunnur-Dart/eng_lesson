import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/letter_model.dart';
import '../services/settings_service.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LetterModel> _lettersData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

Future<void> _loadJsonData() async {
    try {
      final String response = await rootBundle.loadString('assets/letters_data.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        // CHANGED - Ограничиваем список ровно 27 элементами
        _lettersData = data
            .map((item) => LetterModel.fromJson(item))
            .take(27)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Муаллим Сани - 28 Букв'),
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _lettersData.length,
                    itemBuilder: (context, index) {
                      final letterData = _lettersData[index];

                      return LessonCircleButton(
                        letterData: letterData,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                letterData: letterData,
                                // CHANGED - Передаем полный массив уроков для работы с PageView
                                allLetters: _lettersData, 
                                // CHANGED - Передаем текущий индекс выбранного урока
                                currentIndex: index,      
                              ),
                            ),
                          );
                          // Обновляем экран после возвращения из теста, чтобы индикатор перерисовался
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

class LessonCircleButton extends StatelessWidget {
  final LetterModel letterData;
  final VoidCallback onTap;

  const LessonCircleButton({
    super.key,
    required this.letterData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: SettingsService.instance.getLessonProgress(letterData.id),
      builder: (context, snapshot) {
        double progress = snapshot.data ?? 0.0; // Процент прохождения (от 0.0 до 1.0)

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // МОЩНЫЙ КРУГОВОЙ ИНДИКАТОР ПРОГРЕССА ВОКРУГ КНОПКИ УРОКА
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: Colors.teal.shade100,
                  color: Colors.teal.shade700,
                ),
              ),
              // Сама кнопка с буквой
              Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.shade50,
                  border: Border.all(color: Colors.teal.shade300, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    letterData.variations.isNotEmpty 
                        ? letterData.variations.first.symbol 
                        : '${letterData.id}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}