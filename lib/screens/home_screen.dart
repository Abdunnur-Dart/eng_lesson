import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/letter_model.dart';
import '../services/settings_service.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'auth_payment_screen.dart';

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
      if (!mounted) return;
      setState(() {
        _lettersData = data
            .map((item) => LetterModel.fromJson(item))
            .take(27)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPaywallDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Премиум доступ'),
          ],
        ),
        content: const Text(
          'Вторая половина уроков доступна только в Премиум-версии. Разблокируйте все уроки и занимайтесь без ограничений!',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(
                dialogContext,
                MaterialPageRoute(
                  builder: (context) => const AuthPaymentScreen(),
                ),
              );
              if (!mounted) return; // NEW
              setState(() {}); // NEW: Принудительно перестраиваем сетку после возврата с экрана оплаты
            },
            child: const Text('Купить Premium'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 6 : 4;

        final isPremium = SettingsService.instance.isPremium;
        final unlockedCount = (_lettersData.length / 2).ceil();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Арабские буквы'),
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  if (!mounted) return;
                  setState(() {});
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _lettersData.length,
                    itemBuilder: (context, index) {
                      final letterData = _lettersData[index];
                      final bool isLocked = !isPremium && index >= unlockedCount;

                      return LessonCircleButton(
                        letterData: letterData,
                        isLocked: isLocked,
                        onTap: () async {
                          if (isLocked) {
                            _showPaywallDialog(context);
                            return;
                          }

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                letterData: letterData,
                                allLetters: _lettersData,
                                currentIndex: index,
                              ),
                            ),
                          );
                          if (!mounted) return;
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
  final bool isLocked;
  final VoidCallback onTap;

  const LessonCircleButton({
    super.key,
    required this.letterData,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: SettingsService.instance.getLessonProgress(letterData.id),
      builder: (context, snapshot) {
        double progress = snapshot.data ?? 0.0;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: isLocked ? 0.0 : progress,
                  strokeWidth: 5,
                  backgroundColor: isLocked ? Colors.grey.shade300 : Colors.teal.shade100,
                  color: isLocked ? Colors.grey : Colors.teal.shade700,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked ? Colors.grey.shade200 : Colors.teal.shade50,
                  border: Border.all(
                    color: isLocked ? Colors.grey.shade400 : Colors.teal.shade300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isLocked
                      ? Icon(
                          Icons.lock,
                          size: 32,
                          color: Colors.grey.shade600,
                        )
                      : FractionallySizedBox(
                          widthFactor: 0.8,
                          heightFactor: 0.8,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                              letterData.variations.isNotEmpty
                                  ? letterData.variations.first.symbol
                                  : '${letterData.id}',
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
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