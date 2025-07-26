import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF8), // 베이지 배경
      body: SafeArea(
        child: Center(
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFA2BFA3), // 오늘 날짜 강조
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }
}