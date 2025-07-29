import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class DiaryViewPage extends StatefulWidget {
  final DateTime date;
  final List<String> photos;
  final List<Contact> contacts;
  final String? mood;
  final String? content;

  const DiaryViewPage({
    super.key,
    required this.date,
    required this.photos,
    required this.contacts,
    this.mood,
    this.content,
  });

  @override
  State<DiaryViewPage> createState() => _DiaryViewPageState();
}

class _DiaryViewPageState extends State<DiaryViewPage> {
  bool _aiModalShown = false;

  String get formattedDate => '${widget.date.year}년 ${widget.date.month}월 ${widget.date.day}일';

  String get moodDescription {
    final moodMap = {
      '😊': '행복',
      '😄': '기쁨',
      '🤗': '포옹',
      '😐': '보통',
      '😌': '편안',
      '😴': '졸림',
      '😔': '슬픔',
      '😢': '우는',
      '😡': '화남',
    };
    return moodMap[widget.mood] ?? '선택 안함';
  }

  void _showAIModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIDialogModal(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 일기 본문이 없고, 아직 모달을 띄우지 않았다면 자동으로 띄움
    if ((widget.content == null || widget.content!.trim().isEmpty) && !_aiModalShown) {
      _aiModalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAIModal(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 상세'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAIModal(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        tooltip: 'AI와 대화',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.emoji_emotions, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    widget.mood ?? '😐',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    moodDescription,
                    style: const TextStyle(fontSize: 16, color: Colors.purple, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.photos.isNotEmpty) ...[
                const Text('사진', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.photos[idx]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (widget.contacts.isNotEmpty) ...[
                const Text('공유한 연락처', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...widget.contacts.map((c) => ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(c.displayName.isNotEmpty ? c.displayName : '이름 없음'),
                      subtitle: Text(c.phones.isNotEmpty ? c.phones.first.number : '번호 없음'),
                    )),
                const SizedBox(height: 24),
              ],
              const Text('오늘의 한마디', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.content?.trim().isNotEmpty == true
                      ? widget.content!
                      : '아직 일기 본문은 작성하지 않았어요.',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AIDialogModal extends StatefulWidget {
  const AIDialogModal({super.key});

  @override
  State<AIDialogModal> createState() => _AIDialogModalState();
}

class _AIDialogModalState extends State<AIDialogModal> {
  final List<Map<String, String>> messages = [
    {'role': 'ai', 'text': '안녕하세요! 무엇이 궁금하신가요?'},
  ];
  final TextEditingController controller = TextEditingController();
  bool isSending = false;

  void _sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({'role': 'user', 'text': text});
      controller.clear();
      isSending = true;
    });
    // 실제 AI 연동 대신 1초 후 AI 답변 예시
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add({'role': 'ai', 'text': 'AI 답변 예시: "$text"에 대해 생각해볼게요!'});
        isSending = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.smart_toy, color: Colors.deepPurple),
                SizedBox(width: 10),
                Text('AI와 대화', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final msg = messages[idx];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.blue[900] : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                isSending
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.deepPurple),
                        onPressed: _sendMessage,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 