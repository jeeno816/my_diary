import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer';
import 'login_page.dart';
import 'photo_contact_mood_page.dart';
import 'diary_view_page.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  Map<DateTime, List<String>> _photosByDate = {};
  Map<DateTime, List<Contact>> _contactsByDate = {};
  Map<DateTime, String> _moodsByDate = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showPhotoContactMoodPage(selectedDay);
  }

  void _showPhotoContactMoodPage(DateTime selectedDay) {
    final normalizedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final existingPhotos = _photosByDate[normalizedDate] ?? [];
    final existingContacts = _contactsByDate[normalizedDate] ?? [];
    final existingMood = _moodsByDate[normalizedDate];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PhotoContactMoodPage(
          selectedDate: selectedDay,
          initialPhotos: existingPhotos,
          initialContacts: existingContacts,
          initialMood: existingMood,
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          _photosByDate[normalizedDate] = result['photos'];
          _contactsByDate[normalizedDate] = result['contacts'];
          _moodsByDate[normalizedDate] = result['mood'];
        });
        final photoCount = result['photos'].length;
        final contactCount = result['contacts'].length;
        final moodDescription = _getMoodDescription(result['mood']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedDay.month}월 ${selectedDay.day}일에 ${photoCount}장의 사진, ${contactCount}명의 연락처, ${moodDescription} 기분이 저장되었습니다.'),
          ),
        );
        // 일기 상세 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryViewPage(
              date: selectedDay,
              photos: List<String>.from(result['photos']),
              contacts: List<Contact>.from(result['contacts']),
              mood: result['mood'],
            ),
          ),
        );
      }
    });
  }

  String _getMoodDescription(String? mood) {
    if (mood == null) return '선택 안함';
    final moodDescriptions = {
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
    return moodDescriptions[mood] ?? '선택 안함';
  }

  Future<void> _printFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          print('🔥 Firebase ID Token for Swagger:');
          print('Bearer $token');
          print('🔥 Token length: ${token.length}');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firebase 토큰이 터미널에 출력되었습니다!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          print('❌ 토큰이 null입니다.');
        }
      } else {
        print('❌ 사용자가 로그인되지 않았습니다.');
      }
    } catch (e) {
      print('❌ 토큰 가져오기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _printFirebaseToken,
            tooltip: 'Firebase 토큰 출력',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user?.email ?? '사용자'}님',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '오늘도 좋은 하루 되세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                cellMargin: EdgeInsets.all(2),
                cellPadding: EdgeInsets.only(bottom: 12),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  return _buildEventMarker(date);
                },
                defaultBuilder: (context, date, _) {
                  if (date.day == 15) {
                    return Container(
                      margin: const EdgeInsets.all(1),
                      child: const Center(
                        child: SizedBox.shrink(), // Hide number for 15th
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.all(1),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '날짜를 터치하여 사진/연락처/기분을 선택하세요\n15일에는 Sample.jpeg 썸네일이 표시됩니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMarker(DateTime date) {
    if (date.day == 15) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/Sample.jpeg',
              fit: BoxFit.cover,
              cacheWidth: 60,
              errorBuilder: (context, error, stackTrace) {
                print('Image load error: $error');
                return Container(
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(
                    Icons.image,
                    size: 15,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
} 