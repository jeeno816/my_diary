import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'login_page.dart';
import 'photo_selection_modal.dart';

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
    
    // 날짜 선택 시 사진 선택 모달 열기
    _showPhotoSelectionModal(selectedDay);
  }

  void _showPhotoSelectionModal(DateTime selectedDay) {
    final normalizedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final existingPhotos = _photosByDate[normalizedDate] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PhotoSelectionModal(
          selectedDate: selectedDay,
          existingPhotos: existingPhotos,
        );
      },
    ).then((selectedPhotos) {
      if (selectedPhotos != null) {
        setState(() {
          _photosByDate[normalizedDate] = selectedPhotos;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedDay.month}월 ${selectedDay.day}일에 ${selectedPhotos.length}장의 사진이 저장되었습니다.')),
        );
      }
    });
  }



  Widget _buildEventMarker(DateTime date) {
    // 각 달의 15일에만 사진 썸네일 표시
    if (date.day == 15) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 사진 썸네일만 표시
            Container(
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
          ],
        ),
      );
    }
    
    // 다른 날짜에는 아무것도 표시하지 않음
    return const SizedBox.shrink();
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
          // 사용자 정보
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
          
          // 달력
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
                // 날짜 셀의 높이를 늘려서 썸네일이 잘 보이도록 조정
                cellMargin: EdgeInsets.all(2),
                cellPadding: EdgeInsets.only(bottom: 12), // 하단 패딩 더 늘리기
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
                // 날짜 셀의 높이를 조정
                defaultBuilder: (context, date, _) {
                  // 15일에는 숫자를 숨기고 사진만 표시
                  if (date.day == 15) {
                    return Container(
                      margin: const EdgeInsets.all(1),
                      child: const Center(
                        child: SizedBox.shrink(), // 숫자 숨기기
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
          
          const SizedBox(height: 16),
          
          const Spacer(),
          
          // 하단 안내
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '날짜를 터치하여 사진을 선택하세요\n15일에는 Sample.jpeg 썸네일이 표시됩니다',
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
} 