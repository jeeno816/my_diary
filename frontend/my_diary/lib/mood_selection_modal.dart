import 'package:flutter/material.dart';

class MoodSelectionModal extends StatefulWidget {
  final DateTime selectedDate;
  final List<String> selectedPhotos;
  final String? existingMood;
  final void Function(String)? onMoodChanged;
  final bool isPageView;

  const MoodSelectionModal({
    super.key,
    required this.selectedDate,
    required this.selectedPhotos,
    this.existingMood,
    this.onMoodChanged,
    this.isPageView = false,
  });

  @override
  State<MoodSelectionModal> createState() => _MoodSelectionModalState();
}

class _MoodSelectionModalState extends State<MoodSelectionModal> {
  String? selectedMood;

  final List<String> moods = [
    '😊', '😄', '🤗',
    '😐', '😌', '😴',
    '😔', '😢', '😡',
  ];

  final List<String> moodDescriptions = [
    '행복', '기쁨', '포옹',
    '보통', '편안', '졸림',
    '슬픔', '우는', '화남',
  ];

  @override
  void initState() {
    super.initState();
    selectedMood = widget.existingMood;
  }

  void _selectMood(String mood) {
    setState(() {
      selectedMood = mood;
    });
    if (widget.onMoodChanged != null) {
      widget.onMoodChanged!(mood);
    }
  }

  void _onComplete() {
    if (widget.isPageView) {
      if (selectedMood != null && widget.onMoodChanged != null) {
        widget.onMoodChanged!(selectedMood!);
      }
    } else {
      final result = {
        'photos': widget.selectedPhotos,
        'mood': selectedMood,
      };
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isPageView ? null : MediaQuery.of(context).size.height * 0.8,
      decoration: widget.isPageView
          ? null
          : const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sentiment_satisfied,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.selectedDate.month}월 ${widget.selectedDate.day}일 기분',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedMood != null 
                            ? '선택된 기분: ${moodDescriptions[moods.indexOf(selectedMood!)]}'
                            : '오늘의 기분을 선택해주세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // 선택된 사진 요약
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '선택된 사진: ${widget.selectedPhotos.length}장',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 기분 선택 그리드
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '오늘의 기분을 선택해주세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: moods.length,
                      itemBuilder: (context, index) {
                        final mood = moods[index];
                        final description = moodDescriptions[index];
                        final isSelected = selectedMood == mood;

                        return GestureDetector(
                          onTap: () => _selectMood(mood),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.purple.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(color: Colors.purple, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  mood,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.purple : Colors.grey[600],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼 (PageView 모드에서는 숨김)
          if (!widget.isPageView)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('이전'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedMood == null ? null : _onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 