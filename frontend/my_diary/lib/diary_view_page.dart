import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class DiaryViewPage extends StatefulWidget {
  final int diaryId;
  final DateTime date;

  const DiaryViewPage({
    super.key,
    required this.diaryId,
    required this.date,
  });

  @override
  State<DiaryViewPage> createState() => _DiaryViewPageState();
}

class _DiaryViewPageState extends State<DiaryViewPage> {
  bool _aiModalShown = false;
  bool _isLoading = true;
  Map<String, dynamic>? _diaryData;
  String? _error;
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isSendingMessage = false;
  
  // API 서버 주소
  static const String _baseUrl = 'https://mydiary-main.up.railway.app';

  String get formattedDate {
    if (_diaryData != null) {
      final dateStr = _diaryData!['date'];
      final date = DateTime.parse(dateStr);
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
    return '${widget.date.year}년 ${widget.date.month}월 ${widget.date.day}일';
  }

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
    final mood = _diaryData?['mood'];
    return moodMap[mood] ?? '선택 안함';
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

  Future<void> _loadDiaryData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getFirebaseToken();
      if (token == null) {
        setState(() {
          _error = 'Firebase 토큰을 가져올 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/diaries/${widget.diaryId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _diaryData = data;
          _isLoading = false;
        });
        print('✅ 일기 데이터 로드 완료: ${data['id']}');
        
        // 일기 본문이 없으면 자동으로 AI 대화창 열기 (사진이 있어도 본문이 없으면 열림)
        print('🔍 일기 본문 확인: ${data['content']}');
        print('🔍 사진 개수: ${data['photos']?.length ?? 0}');
        if (data['content'] == null || data['content'].toString().trim().isEmpty) {
          print('✅ 본문이 없어서 AI 대화창을 열겠습니다');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_aiModalShown) {
              _aiModalShown = true;
              _showAIModal(context);
            }
          });
        } else {
          print('❌ 본문이 있어서 AI 대화창을 열지 않습니다');
        }
      } else {
        setState(() {
          _error = '일기 데이터를 가져올 수 없습니다. (${response.statusCode})';
          _isLoading = false;
        });
        print('❌ 일기 데이터 로드 실패: ${response.statusCode}');
        print('응답: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류: $e';
        _isLoading = false;
      });
      print('❌ 일기 데이터 로드 오류: $e');
    }
  }



  void _showAIModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) => AIDialogModal(
        initialMessages: _chatMessages,
        diaryId: widget.diaryId,
        onDiaryUpdated: _loadDiaryData,
        onShowSaveModal: _showSaveDiaryModal,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDiaryData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF8),
      appBar: AppBar(
        title: const Text('일기 상세'),
        backgroundColor: const Color(0xFFFDFBF8),
        foregroundColor: Colors.black,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAIModal(context),
        backgroundColor: const Color(0xFFA2BFA3),
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble, color: Colors.white),
        tooltip: 'AI와 대화',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDiaryData,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _diaryData == null
                  ? const Center(
                      child: Text('일기 데이터를 불러올 수 없습니다.'),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _diaryData!['mood'] ?? '😐',
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    moodDescription,
                                    style: const TextStyle(fontSize: 16, color: Color(0xFFA2BFA3), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_diaryData!['photos'] != null && (_diaryData!['photos'] as List).isNotEmpty) ...[
                              const Text('사진', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (_diaryData!['photos'] as List).length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, idx) {
                                    final photo = _diaryData!['photos'][idx];
                                    final imageUrl = '$_baseUrl${photo['path']}';
                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.all(16),
                                            child: GestureDetector(
                                              onTap: () => Navigator.of(context).pop(), // 탭하면 닫히게
                                              child: InteractiveViewer(
                                                child: Image.network(
                                                  '$_baseUrl${photo['path']}',
                                                  fit: BoxFit.contain,
                                                  loadingBuilder: (context, child, progress) {
                                                    if (progress == null) return child;
                                                    return const Center(child: CircularProgressIndicator());
                                                  },
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Image.network(
                                          '$_baseUrl${photo['path']}',
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
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            const Text('오늘의 한마디', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF6F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _diaryData!['content']?.toString().trim().isNotEmpty == true
                                    ? _diaryData!['content'].toString()
                                    : '아직 일기 본문은 작성하지 않았어요.',
                                style: const TextStyle(fontSize: 15, color: Color(0xFF000000)),
                              ),
                            ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveDiaryModal(String editedText) {
    print('🔥🔥🔥 부모 위젯에서 일기 저장 모달 호출됨 🔥🔥🔥');
    print('🔥 editedText: $editedText');
    print('🔥 editedText 길이: ${editedText.length}');
    print('🔥 현재 컨텍스트: $context');
    print('🔥 mounted 상태: $mounted');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        print('🔥🔥🔥 부모 위젯 다이얼로그 빌더 실행됨 🔥🔥🔥');
        return WillPopScope(
          onWillPop: () async {
            print('🔥 뒤로가기 버튼 비활성화됨');
            return false;
          },
          child: AlertDialog(
            title: const Text('일기 저장'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI가 생성한 일기를 저장하시겠습니까?'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    editedText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('🔥 부모 위젯 일기 저장 취소 버튼 클릭');
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('🔥 부모 위젯 일기 저장 버튼 클릭');
                  Navigator.of(dialogContext).pop();
                  _saveDiaryContent(editedText);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA2BFA3),
                  foregroundColor: Colors.white,
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      print('🔥🔥🔥 부모 위젯 다이얼로그가 닫힘 🔥🔥🔥');
    }).catchError((error) {
      print('🔥🔥🔥 부모 위젯 다이얼로그 표시 오류: $error 🔥🔥🔥');
    });
  }

  Future<void> _saveDiaryContent(String content) async {
    try {
      print('💾 일기 내용 저장 시작: $content');
      
      final token = await _getFirebaseToken();
      if (token == null) {
        print('❌ Firebase 토큰 없음');
        return;
      }
      
      // PATCH API 호출
      final url = 'https://mydiary-main.up.railway.app/diaries/${widget.diaryId}';
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'text': content,
        }),
      );
      
      print('📡 PATCH 응답 상태: ${response.statusCode}');
      print('📡 PATCH 응답 내용: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Diary content updated successfully') {
          print('✅ 일기 내용 저장 성공');
          
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('일기 내용이 저장되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 상세 페이지 새로고침
          _loadDiaryData();
        } else {
          print('❌ 예상하지 못한 응답: ${data['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 실패: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ PATCH 요청 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ 일기 저장 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AIDialogModal extends StatefulWidget {
  final List<Map<String, dynamic>> initialMessages;
  final int diaryId;
  final VoidCallback? onDiaryUpdated;
  final Function(String)? onShowSaveModal;

  const AIDialogModal({
    super.key,
    required this.initialMessages,
    required this.diaryId,
    this.onDiaryUpdated,
    this.onShowSaveModal,
  });

  @override
  State<AIDialogModal> createState() => _AIDialogModalState();
}

class _AIDialogModalState extends State<AIDialogModal> {
  late List<Map<String, dynamic>> messages;
  final TextEditingController controller = TextEditingController();
  bool isSending = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    messages = List<Map<String, dynamic>>.from(widget.initialMessages);
    
    // 초기 메시지가 없으면 로딩 상태로 설정하고 직접 로드
    if (messages.isEmpty) {
      isLoading = true;
      _loadChatHistory();
    } else {
      isLoading = false;
    }
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _getFirebaseToken();
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://mydiary-main.up.railway.app/ai/ai_logs/${widget.diaryId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chats = List<Map<String, dynamic>>.from(data['chats']);
        
        setState(() {
          messages = chats.map<Map<String, dynamic>>((chat) => {
            'role': chat['by'],
            'text': chat['text'],
          }).toList();
          isLoading = false;
        });
        print('✅ AI 채팅 내역 로드 완료: ${messages.length}개 메시지');
      } else {
        print('❌ AI 채팅 내역 로드 실패: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ AI 채팅 내역 로드 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      messages.add({'role': 'user', 'text': text});
      controller.clear();
      isSending = true;
    });

    try {
      final token = await _getFirebaseToken();
      if (token == null) {
        setState(() {
          isSending = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('https://mydiary-main.up.railway.app/ai/ai_logs/${widget.diaryId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📨 AI 응답 데이터: $data');
        
        final chats = List<Map<String, dynamic>>.from(data['chats']);
        
        setState(() {
          // 마지막 AI 메시지만 추가 (이전 메시지들은 이미 있으므로)
          if (chats.isNotEmpty) {
            final lastChat = chats.last;
            if (lastChat['by'] == 'ai') {
              messages.add({'role': 'ai', 'text': lastChat['text']});
            }
          }
          isSending = false;
        });

        // is_edit_text가 true인지 확인
        print('🔍 is_edit_text 확인: ${data['is_edit_text']}');
        print('🔍 edited_text 확인: ${data['edited_text']}');
        print('🔍 edited_text 타입: ${data['edited_text'].runtimeType}');
        print('🔍 edited_text 길이: ${data['edited_text'].toString().length}');
        
        if (data['is_edit_text'] == true && data['edited_text'] != null && data['edited_text'].toString().isNotEmpty) {
          print('🔥🔥🔥 iOS 모달 표시 시작 🔥🔥🔥');
          print('🔥 is_edit_text: ${data['is_edit_text']}');
          print('🔥 edited_text: ${data['edited_text']}');
          print('🔥 edited_text 길이: ${data['edited_text'].toString().length}');
          print('🔥 현재 컨텍스트: $context');
          print('🔥 mounted 상태: $mounted');
          
          // 부모 위젯에 일기 저장 모달 표시 요청
          print('🔥 부모 위젯에 일기 저장 모달 표시 요청');
          widget.onDiaryUpdated?.call(); // 부모 위젯 새로고침
          
          // AI 채팅 모달 닫기
          print('🔥 AI 채팅 모달 닫기 시도');
          Navigator.of(context).pop(); // AI 채팅 모달 닫기
          print('🔥 AI 채팅 모달 닫기 완료');
          
          // 부모 위젯에서 일기 저장 모달 표시
          Future.delayed(const Duration(milliseconds: 300), () {
            print('🔥 부모 위젯에서 일기 저장 모달 표시 시도');
            widget.onShowSaveModal?.call(data['edited_text']);
          });
        } else {
          print('🔥🔥🔥 모달 표시 조건 불충족 🔥🔥🔥');
          print('🔥 is_edit_text: ${data['is_edit_text']}');
          print('🔥 edited_text null: ${data['edited_text'] == null}');
          print('🔥 edited_text empty: ${data['edited_text'].toString().isEmpty}');
        }
      } else {
        setState(() {
          messages.add({'role': 'ai', 'text': '죄송합니다. 응답을 받지 못했습니다.'});
          isSending = false;
        });
      }
    } catch (e) {
      setState(() {
        messages.add({'role': 'ai', 'text': '네트워크 오류가 발생했습니다.'});
        isSending = false;
      });
    }
  }

  void _showSaveDiaryModal(String editedText) {
    print('🔥🔥🔥 _showSaveDiaryModal 호출됨 🔥🔥🔥');
    print('🔥 editedText: $editedText');
    print('🔥 editedText 길이: ${editedText.length}');
    print('🔥 현재 컨텍스트: $context');
    print('🔥 mounted 상태: $mounted');
    
    // iOS에서 모달이 안 뜨는 문제를 해결하기 위해 여러 방법 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔥 PostFrameCallback 실행됨');
      print('🔥 PostFrameCallback 내부 mounted 상태: $mounted');
      
      if (mounted) {
        print('🔥🔥🔥 showDialog 호출 시작 🔥🔥🔥');
        
        // iOS에서 모달을 강제로 표시하기 위한 방법
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (BuildContext dialogContext) {
            print('🔥🔥🔥 iOS 다이얼로그 빌더 실행됨 🔥🔥🔥');
            print('🔥 dialogContext: $dialogContext');
            
            return WillPopScope(
              onWillPop: () async {
                print('🔥 뒤로가기 버튼 비활성화됨');
                return false;
              },
              child: AlertDialog(
                title: const Text('일기 저장'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI가 생성한 일기를 저장하시겠습니까?'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        editedText,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      print('🔥 iOS 일기 저장 취소 버튼 클릭');
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('🔥 iOS 일기 저장 버튼 클릭');
                      Navigator.of(dialogContext).pop();
                      _saveDiaryContent(editedText);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA2BFA3),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('저장'),
                  ),
                ],
              ),
            );
          },
        ).then((_) {
          print('🔥🔥🔥 iOS 다이얼로그가 닫힘 🔥🔥🔥');
        }).catchError((error) {
          print('🔥🔥🔥 iOS 다이얼로그 표시 오류: $error 🔥🔥🔥');
          print('🔥 오류 스택 트레이스: ${StackTrace.current}');
          
          // iOS에서 실패하면 SnackBar로 대체
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('일기 저장 모달을 표시할 수 없습니다.'),
              action: SnackBarAction(
                label: '저장',
                onPressed: () => _saveDiaryContent(editedText),
              ),
            ),
          );
        });
      } else {
        print('🔥🔥🔥 위젯이 마운트되지 않음 🔥🔥🔥');
      }
    });
  }

  Future<void> _saveDiaryContent(String content) async {
    try {
      print('💾 일기 내용 저장 시작: $content');
      
      final token = await _getFirebaseToken();
      if (token == null) {
        print('❌ Firebase 토큰 없음');
        return;
      }
      
      // PATCH API 호출
      final url = 'https://mydiary-main.up.railway.app/diaries/${widget.diaryId}';
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'text': content,
        }),
      );
      
      print('📡 PATCH 응답 상태: ${response.statusCode}');
      print('📡 PATCH 응답 내용: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Diary content updated successfully') {
          print('✅ 일기 내용 저장 성공');
          
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('일기 내용이 저장되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 상세 페이지 새로고침
          widget.onDiaryUpdated?.call();
        } else {
          print('❌ 예상하지 못한 응답: ${data['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 실패: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ PATCH 요청 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ 일기 저장 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFA2BFA3).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.smart_toy, color: Color(0xFFA2BFA3)),
                SizedBox(width: 10),
                Text('AI와 대화', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('AI 채팅을 불러오는 중...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, idx) {
                      final msg = messages[idx];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFFCFE3CC) : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: isUser ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isUser ? const Color(0xFF000000) : const Color(0xFF303030),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onSubmitted: isLoading ? null : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                isSending
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : GestureDetector(
                        onTap: isLoading ? null : _sendMessage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA2BFA3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white,
                            size: 24,
                          ),
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