import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class DiaryViewPage extends StatelessWidget {
  final DateTime date;
  final List<String> photos;
  final List<Contact> contacts;
  final String? mood;

  const DiaryViewPage({
    super.key,
    required this.date,
    required this.photos,
    required this.contacts,
    this.mood,
  });

  String get formattedDate => '${date.year}년 ${date.month}월 ${date.day}일';

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
    return moodMap[mood] ?? '선택 안함';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 상세'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜
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

              // 기분
              Row(
                children: [
                  const Icon(Icons.emoji_emotions, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    mood ?? '😐',
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

              // 사진
              if (photos.isNotEmpty) ...[
                const Text('사진', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(photos[idx]),
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

              // 연락처
              if (contacts.isNotEmpty) ...[
                const Text('공유한 연락처', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...contacts.map((c) => ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(c.displayName.isNotEmpty ? c.displayName : '이름 없음'),
                      subtitle: Text(c.phones.isNotEmpty ? c.phones.first.number : '번호 없음'),
                    )),
                const SizedBox(height: 24),
              ],

              // 메모/일기 본문(추후 확장 가능)
              const Text('오늘의 한마디', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '아직 일기 본문은 작성하지 않았어요.',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 