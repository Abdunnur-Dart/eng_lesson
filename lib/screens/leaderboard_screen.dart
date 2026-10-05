import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildGlassContainer({
    required BuildContext context,
    required Widget child,
    double borderRadius = 20,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = isDark
        ? [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ]
        : [
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.35),
          ];

    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: defaultGradient,
            ),
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    // Заменили зеленый на глубокий индиго / неон
    final primaryColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              title: Text(
                'Таблица лидеров',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              centerTitle: true,
              backgroundColor: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.3),
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: primaryColor,
                labelColor: primaryColor,
                unselectedLabelColor: textColor.withValues(alpha: 0.6),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'За всё время'),
                  Tab(text: 'За эту неделю'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF0F172A),
                          Color(0xFF1E1B4B),
                          Color(0xFF09090B),
                        ]
                      : const [
                          Color(0xFFF8FAFC),
                          Color(0xFFEEF2FF),
                          Color(0xFFE0E7FF),
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Вкладка "За всё время" — сортирует по общему полю totalPoints
                _buildLeaderboardList(
                  field: 'totalPoints',
                  isWeekly: false,
                  currentUserId: currentUserId,
                  isDark: isDark,
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
                // Вкладка "За эту неделю" — считает сумму за последние 7 дней динамически
                _buildLeaderboardList(
                  field: 'weeklyPoints',
                  isWeekly: true,
                  currentUserId: currentUserId,
                  isDark: isDark,
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList({
    required String field,
    required bool isWeekly,
    required String? currentUserId,
    required bool isDark,
    required Color textColor,
    required Color primaryColor,
  }) {
    // Если это общая таблица — берем напрямую из документов пользователей
    if (!isWeekly) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy(field, descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          return _handleSnapshot(snapshot, field, currentUserId, isDark, textColor, primaryColor);
        },
      );
    }

    // Для недельной таблицы: вычисляем дату 7 дней назад
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки', style: TextStyle(color: textColor)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('Пока нет данных', style: TextStyle(color: textColor)));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _calculateWeeklyPoints(docs, weekAgo),
          builder: (context, weeklySnapshot) {
            if (!weeklySnapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: primaryColor));
            }

            final sortedUsers = weeklySnapshot.data!;

            if (sortedUsers.isEmpty) {
              return Center(
                child: Text(
                  'Нет активности за эту неделю',
                  style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: sortedUsers.length,
              itemBuilder: (context, index) {
                final userData = sortedUsers[index];
                final userId = userData['id'];
                final isCurrentUser = userId == currentUserId;
                final name = userData['name'];
                final points = userData['points'];
                final rank = index + 1;

                Color? rankColor;
                IconData? rankIcon;

                if (rank == 1) {
                  rankColor = const Color(0xFFFFD700);
                  rankIcon = Icons.emoji_events;
                } else if (rank == 2) {
                  rankColor = const Color(0xFFC0C0C0);
                  rankIcon = Icons.emoji_events;
                } else if (rank == 3) {
                  rankColor = const Color(0xFFCD7F32);
                  rankIcon = Icons.emoji_events;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _buildGlassContainer(
                    context: context,
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    borderColor: isCurrentUser ? primaryColor.withValues(alpha: 0.8) : null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: rankIcon != null
                              ? Icon(rankIcon, color: rankColor, size: 26)
                              : Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                  color: isCurrentUser ? primaryColor : textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isCurrentUser)
                                Text(
                                  'Вы',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: primaryColor.withValues(alpha: 0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$points',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Вспомогательный метод для обработки стандартного вывода (За всё время)
  Widget _handleSnapshot(
    AsyncSnapshot<QuerySnapshot> snapshot,
    String field,
    String? currentUserId,
    bool isDark,
    Color textColor,
    Color primaryColor,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (snapshot.hasError) {
      return Center(child: Text('Ошибка загрузки лидерборда', style: TextStyle(color: textColor)));
    }

    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return Center(child: Text('Пока нет данных в таблице лидеров', style: TextStyle(color: textColor.withValues(alpha: 0.7))));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final userId = docs[index].id;
        final isCurrentUser = userId == currentUserId;

        String name = _formatName(data, index);
        final points = (data[field] as num?)?.toInt() ?? 0;
        final rank = index + 1;

        Color? rankColor;
        IconData? rankIcon;

        if (rank == 1) {
          rankColor = const Color(0xFFFFD700);
          rankIcon = Icons.emoji_events;
        } else if (rank == 2) {
          rankColor = const Color(0xFFC0C0C0);
          rankIcon = Icons.emoji_events;
        } else if (rank == 3) {
          rankColor = const Color(0xFFCD7F32);
          rankIcon = Icons.emoji_events;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _buildGlassContainer(
            context: context,
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            borderColor: isCurrentUser ? primaryColor.withValues(alpha: 0.8) : null,
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: rankIcon != null
                      ? Icon(rankIcon, color: rankColor, size: 26)
                      : Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: isCurrentUser ? primaryColor : textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCurrentUser)
                        Text(
                          'Вы',
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$points',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Метод форматирования имени
  String _formatName(Map<String, dynamic> data, int index) {
    String name = data['displayName'] ?? '';
    if (name.isEmpty) {
      final email = data['email'] as String? ?? '';
      if (email.contains('@')) {
        final parts = email.split('@');
        final prefix = parts[0];
        if (prefix.length > 3) {
          name = '${prefix.substring(0, 3)}***@${parts[1]}';
        } else {
          name = '***@${parts[1]}';
        }
      } else {
        name = 'Пользователь ${index + 1}';
      }
    }
    return name;
  }

  // Динамический подсчет очков за последние 7 дней
  Future<List<Map<String, dynamic>>> _calculateWeeklyPoints(
      List<QueryDocumentSnapshot> userDocs, DateTime weekAgo) async {
    List<Map<String, dynamic>> results = [];

    for (var doc in userDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = doc.id;
      String name = _formatName(data, 0);

      int weeklySum = 0;

      try {
        final historySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('points_history')
            .where('timestamp', isGreaterThanOrEqualTo: weekAgo)
            .get();

        for (var historyDoc in historySnapshot.docs) {
          final hData = historyDoc.data();
          weeklySum += (hData['points'] as num?)?.toInt() ?? 0;
        }
      } catch (e) {
        weeklySum = (data['weeklyPoints'] as num?)?.toInt() ?? (data['totalPoints'] as num?)?.toInt() ?? 0;
      }

      results.add({
        'id': userId,
        'name': name,
        'points': weeklySum,
      });
    }

    results.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    return results;
  }
}
