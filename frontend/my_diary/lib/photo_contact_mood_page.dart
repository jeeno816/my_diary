import 'package:flutter/material.dart';
import 'photo_selection_modal.dart';
import 'mood_selection_modal.dart';

class PhotoContactMoodPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<String> initialPhotos;
  final String? initialMood;

  const PhotoContactMoodPage({
    super.key,
    required this.selectedDate,
    this.initialPhotos = const [],
    this.initialMood,
  });

  @override
  State<PhotoContactMoodPage> createState() => _PhotoContactMoodPageState();
}

class _PhotoContactMoodPageState extends State<PhotoContactMoodPage> {
  late PageController _pageController;
  int _currentPage = 0;

  List<String> selectedPhotos = [];
  String? selectedMood;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    selectedPhotos = List.from(widget.initialPhotos);
    selectedMood = widget.initialMood;
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _onPhotosChanged(List<String> photos) {
    setState(() {
      selectedPhotos = photos;
    });
  }

  void _onMoodChanged(String mood) {
    setState(() {
      selectedMood = mood;
    });
  }

  void _onComplete() {
    Navigator.pop(context, {
      'photos': selectedPhotos,
      'mood': selectedMood,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                // 사진 선택
                PhotoSelectionModal(
                  selectedDate: widget.selectedDate,
                  existingPhotos: selectedPhotos,
                  onPhotosChanged: _onPhotosChanged,
                  isPageView: true,
                ),
                // 기분 선택
                MoodSelectionModal(
                  selectedDate: widget.selectedDate,
                  selectedPhotos: selectedPhotos,
                  existingMood: selectedMood,
                  onMoodChanged: _onMoodChanged,
                  isPageView: true,
                ),
              ],
            ),
          ),
          // 하단 네비게이션 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goToPage(_currentPage - 1),
                      child: const Text('이전'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: _currentPage < 1
                      ? ElevatedButton(
                          onPressed: selectedPhotos.isNotEmpty ? () => _goToPage(1) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('다음'),
                        )
                      : ElevatedButton(
                          onPressed: selectedMood != null ? _onComplete : null,
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