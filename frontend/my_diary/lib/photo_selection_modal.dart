import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PhotoSelectionModal extends StatefulWidget {
  final DateTime selectedDate;
  final List<String> existingPhotos;
  final void Function(List<String>)? onPhotosChanged;
  final bool isPageView;

  const PhotoSelectionModal({
    super.key,
    required this.selectedDate,
    this.existingPhotos = const [],
    this.onPhotosChanged,
    this.isPageView = false,
  });

  @override
  State<PhotoSelectionModal> createState() => _PhotoSelectionModalState();
}

class _PhotoSelectionModalState extends State<PhotoSelectionModal> {
  final ImagePicker _picker = ImagePicker();
  List<String> selectedPhotos = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedPhotos = List.from(widget.existingPhotos);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        isLoading = true;
      });

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          selectedPhotos.addAll(images.map((image) => image.path));
        });
        if (widget.onPhotosChanged != null) {
          widget.onPhotosChanged!(selectedPhotos);
        }
        if (!widget.isPageView) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${images.length}장의 사진이 추가되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (!widget.isPageView) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 선택 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      selectedPhotos.removeAt(index);
    });
    if (widget.onPhotosChanged != null) {
      widget.onPhotosChanged!(selectedPhotos);
    }
  }

  void _showImageSourceDialog() {
    _pickImage(ImageSource.gallery);
  }

  void _proceedToContactSelection() {
    if (widget.isPageView) {
      if (widget.onPhotosChanged != null) {
        widget.onPhotosChanged!(selectedPhotos);
      }
    } else {
      Navigator.pop(context, selectedPhotos);
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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: widget.isPageView
                  ? null
                  : const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.selectedDate.month}월 ${widget.selectedDate.day}일 사진',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '선택된 사진: ${selectedPhotos.length}장',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isPageView)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),

          // 사진 추가 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _showImageSourceDialog,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library),
                    label: Text(isLoading ? '처리 중...' : '갤러리에서 사진 선택'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 선택된 사진들
          Expanded(
            child: selectedPhotos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '선택된 사진이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '위의 버튼을 눌러 갤러리에서 사진을 선택하세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: selectedPhotos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedPhotos[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.withOpacity(0.2),
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // 삭제 버튼
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedPhotos.isEmpty ? null : _proceedToContactSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('다음'),
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