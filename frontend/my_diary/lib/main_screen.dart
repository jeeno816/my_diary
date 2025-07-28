import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 상단 여백 추가
              const SizedBox(height: 40),
              // 상단 제목
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '지난 일기',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30), // 캘린더와 제목 사이 간격 늘림
                    // 캘린더
                    _buildCalendar(),
                  ],
                ),
              ),
              // 하단 여백 추가
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 일기 작성 화면으로 이동
        },
        backgroundColor: Colors.green[300],
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        // 월 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_focusedDate.month}월',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 요일 헤더
        Row(
          children: ['일', '월', '화', '수', '목', '금', '토']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: day == '일' ? Colors.red : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        // 날짜 그리드
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 일요일이 0이 되도록
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> calendarDays = [];

    // 이전 달의 마지막 날짜들
    final lastDayOfPrevMonth = DateTime(_focusedDate.year, _focusedDate.month, 0);
    for (int i = firstWeekday - 1; i >= 0; i--) {
      final day = lastDayOfPrevMonth.day - i;
      calendarDays.add(
        Expanded(
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    // 현재 달의 날짜들
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = day == DateTime.now().day && 
                     _focusedDate.month == DateTime.now().month &&
                     _focusedDate.year == DateTime.now().year;
      final isSelected = day == _selectedDate.day &&
                        _focusedDate.month == _selectedDate.month &&
                        _focusedDate.year == _selectedDate.year;

      calendarDays.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = DateTime(_focusedDate.year, _focusedDate.month, day);
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : (isToday ? Colors.green[100] : null),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 다음 달의 첫 날짜들
    final remainingDays = 42 - calendarDays.length; // 6주 * 7일 = 42
    for (int day = 1; day <= remainingDays; day++) {
      calendarDays.add(
        Expanded(
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    // 6주로 나누어 표시
    return Column(
      children: [
        for (int week = 0; week < 6; week++)
          Row(
            children: calendarDays.sublist(week * 7, (week + 1) * 7),
          ),
      ],
    );
  }
} 