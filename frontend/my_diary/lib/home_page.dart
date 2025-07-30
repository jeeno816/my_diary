import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'photo_contact_mood_page.dart';
import 'diary_view_page.dart';

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
  Map<DateTime, String> _moodsByDate = {};
  
  // 월별 일기 데이터
  Map<String, List<Map<String, dynamic>>> _monthlyDiaryData = {};
  bool _isLoading = false;
  bool _isCreatingDiary = false;
  
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
    final existingMood = _moodsByDate[normalizedDate];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PhotoContactMoodPage(
          selectedDate: selectedDay,
          initialPhotos: existingPhotos,
          initialMood: existingMood,
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          _photosByDate[normalizedDate] = result['photos'];
          _moodsByDate[normalizedDate] = result['mood'];
        });
        final photoCount = result['photos'].length;
        final moodDescription = _getMoodDescription(result['mood']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedDay.month}월 ${selectedDay.day}일에 ${photoCount}장의 사진, ${moodDescription} 기분이 저장되었습니다.'),
          ),
        );
        // 새 일기 생성 API 호출
        _createDiary(selectedDay, result['photos'], result['mood']);
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

  Future<void> _createDiary(DateTime date, List<String> photos, String? mood) async {
    setState(() {
      _isCreatingDiary = true;
    });

    try {
      final token = await _getFirebaseToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase 토큰을 가져올 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // multipart/form-data 요청 생성
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/diaries/'),
      );

      // 헤더 설정
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['accept'] = 'application/json';

      // 날짜 추가
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      request.fields['date'] = dateStr;

      // 기분 추가
      request.fields['mood'] = mood ?? '😐';

      // 내용 추가 (빈 문자열)
      request.fields['content'] = '';

      // 사진 파일들 추가
      for (String photoPath in photos) {
        final file = File(photoPath);
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'photos',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      // 요청 전송
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final diaryId = jsonData['diary_id'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기가 성공적으로 생성되었습니다. (ID: $diaryId)'),
            backgroundColor: Colors.green,
          ),
        );

        // 상세 페이지로 이동
        _navigateToDiaryDetail(date, diaryId);
        
        // 월별 데이터 새로고침
        _refreshMonthlyData(date);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기 생성 실패: ${jsonData['message'] ?? '알 수 없는 오류'}'),
            backgroundColor: Colors.red,
          ),
        );
        print('❌ 일기 생성 실패: ${response.statusCode}');
        print('응답: $responseData');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('네트워크 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('❌ 일기 생성 오류: $e');
    } finally {
      setState(() {
        _isCreatingDiary = false;
      });
    }
  }

  void _refreshMonthlyData(DateTime date) {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    _monthlyDiaryData.remove(monthKey);
    _loadMonthlyDiaryData(date);
  }

  void _navigateToDiaryDetail(DateTime date, int diaryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryViewPage(
          diaryId: diaryId,
          date: date,
        ),
      ),
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
          if (_isCreatingDiary)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _isCreatingDiary ? null : _printFirebaseToken,
            tooltip: 'Firebase 토큰 출력',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isCreatingDiary ? null : () async {
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
            child: Opacity(
              opacity: _isCreatingDiary ? 0.5 : 1.0,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: _isCreatingDiary ? null : _onDaySelected,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: _isCreatingDiary ? null : _onPageChanged,
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
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              _isCreatingDiary 
                  ? '일기를 생성하고 있습니다...\n잠시만 기다려주세요'
                  : '날짜를 터치하여 일기를 작성하거나 확인하세요\n썸네일이 있는 날짜는 사진이 포함된 일기입니다',
              style: TextStyle(
                fontSize: 12,
                color: _isCreatingDiary ? Colors.blue[600] : Colors.grey[600],
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