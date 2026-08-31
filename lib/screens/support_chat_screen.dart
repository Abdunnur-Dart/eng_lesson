import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous_user';
    final userEmail = user?.email ?? 'Гость (${userId.substring(0, 5)})';

    try {
      final chatDocRef = FirebaseFirestore.instance.collection('support_chats').doc(userId);

      // 1. Обновляем информацию о чате в корневом документе
      await chatDocRef.set({
        'userEmail': userEmail,
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Добавляем само сообщение в подколлекцию messages
      await chatDocRef.collection('messages').add({
        'text': text,
        'sender': 'user', // 'user' или 'admin'
        'createdAt': FieldValue.serverTimestamp(),
        'userEmail': userEmail,
      });

      // Плавная прокрутка к последнему сообщению
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Ошибка отправки сообщения: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous_user';

    return Scaffold(
      resizeToAvoidBottomInset: true, // NEW
      appBar: AppBar(
        title: const Text('Чат с поддержкой', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea( // NEW
        child: GestureDetector( // NEW
          onTap: () => FocusScope.of(context).unfocus(), // NEW
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('support_chats')
                      .doc(userId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Если данные еще грузятся
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      );
                    }

                    // Если реальная ошибка (нет интернета или правил)
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Не удалось загрузить сообщения.\nПроверьте интернет-соединение.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // Если сообщений еще нет — показываем аккуратную заглушку
                    if (docs.isEmpty) {
                      return SingleChildScrollView( // CHANGED
                        physics: const AlwaysScrollableScrollPhysics(), // NEW
                        child: SizedBox( // NEW
                          height: MediaQuery.of(context).size.height * 0.6, // NEW
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.teal.shade300),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Здесь пока нет сообщений',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Задайте ваш вопрос разработчику. Мы ответим в этом чате или на вашу почту!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Новые сообщения снизу
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final isUser = data['sender'] == 'user'; // CHANGED: 'assistant' и 'admin' выравниваются слева
                        final text = data['text'] ?? '';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.teal.shade700 : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Поле ввода сообщения
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null, // NEW
                        keyboardType: TextInputType.multiline, // NEW
                        decoration: const InputDecoration(
                          hintText: 'Введите сообщение...',
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.teal),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}