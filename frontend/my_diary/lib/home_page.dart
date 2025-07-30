import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  
  // 월별 일기 데이터
  Map<String, List<Map<String, dynamic>>> _monthlyDiaryData = {};
  bool _isLoading = false;
  
  // API 서버 주소
  static const String _baseUrl = 'https://mydiary-main.up.railway.app';

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _loadMonthlyDiaryData(_focusedDay);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    
    final dayData = _getDayData(selectedDay);
    final hasDiary = dayData?['has_diary'] ?? false;
    final diaryId = dayData?['diary_id'];
    
    if (hasDiary && diaryId != null) {
      // 일기가 있는 경우 - 일기 상세 페이지로 이동
      _navigateToDiaryDetail(selectedDay, diaryId);
    } else {
      // 일기가 없는 경우 - 새 일기 작성 페이지로 이동
      _showPhotoContactMoodPage(selectedDay);
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    _loadMonthlyDiaryData(focusedDay);
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

  Future<String?> _getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        return token;
      }
      return null;
    } catch (e) {
      print('❌ 토큰 가져오기 실패: $e');
      return null;
    }
  }

  Future<void> _printFirebaseToken() async {
    try {
      final token = await _getFirebaseToken();
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
    } catch (e) {
      print('❌ 토큰 가져오기 실패: $e');
    }
  }

  Future<void> _loadMonthlyDiaryData(DateTime date) async {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    
    // 이미 로드된 데이터가 있으면 스킵
    if (_monthlyDiaryData.containsKey(monthKey)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getFirebaseToken();
      if (token == null) {
        print('❌ Firebase 토큰을 가져올 수 없습니다.');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/diaries/month/$monthKey'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final days = List<Map<String, dynamic>>.from(data['days']);
        
        setState(() {
          _monthlyDiaryData[monthKey] = days;
        });
        
        print('✅ $monthKey 월 데이터 로드 완료: ${days.length}일');
      } else {
        print('❌ 월별 일기 데이터 로드 실패: ${response.statusCode}');
        print('응답: ${response.body}');
      }
    } catch (e) {
      print('❌ 월별 일기 데이터 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _getDayData(DateTime date) {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final monthData = _monthlyDiaryData[monthKey];
    if (monthData != null) {
      return monthData.firstWhere(
        (day) => day['day'] == date.day,
        orElse: () => {
          'day': date.day,
          'has_diary': false,
          'thumbnail': null,
          'diary_id': null,
        },
      );
    }
    return null;
  }

  void _navigateToDiaryDetail(DateTime date, int diaryId) {
    // TODO: 일기 상세 페이지로 이동하는 로직 구현
    // 현재는 간단한 다이얼로그로 표시
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${date.month}월 ${date.day}일 일기'),
          content: Text('일기 ID: $diaryId\n이 기능은 추후 구현 예정입니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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
              onPageChanged: _onPageChanged,
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
                  final dayData = _getDayData(date);
                  final hasDiary = dayData?['has_diary'] ?? false;
                  final thumbnail = dayData?['thumbnail'];
                  final diaryId = dayData?['diary_id'];
                  
                  if (hasDiary && thumbnail != null) {
                    // 썸네일이 있는 경우
                    return Container(
                      margin: const EdgeInsets.all(1),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            '$_baseUrl$thumbnail',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  } else if (hasDiary) {
                    // 일기는 있지만 썸네일이 없는 경우
                    return Container(
                      margin: const EdgeInsets.all(1),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.edit_note,
                            size: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // 일기가 없는 경우
                    return Container(
                      margin: const EdgeInsets.all(1),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '날짜를 터치하여 일기를 작성하거나 확인하세요\n썸네일이 있는 날짜는 사진이 포함된 일기입니다',
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
    // 15일 특별 표시 제거 - 이제 API 데이터 기반으로만 표시
    return const SizedBox.shrink();
  }
} 