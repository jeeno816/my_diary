import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'photo_selection_modal.dart';
import 'mood_selection_modal.dart';

class ContactSelectionModal extends StatefulWidget {
  final DateTime selectedDate;
  final List<String> selectedPhotos;
  final List<Contact> existingContacts;
  final void Function(List<Contact>)? onContactsChanged;
  final bool isPageView;

  const ContactSelectionModal({
    super.key,
    required this.selectedDate,
    required this.selectedPhotos,
    this.existingContacts = const [],
    this.onContactsChanged,
    this.isPageView = false,
  });

  @override
  State<ContactSelectionModal> createState() => _ContactSelectionModalState();
}

class _ContactSelectionModalState extends State<ContactSelectionModal> {
  List<Contact> allContacts = [];
  List<Contact> selectedContacts = [];
  List<Contact> filteredContacts = [];
  bool isLoading = true;
  bool hasPermission = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedContacts = List.from(widget.existingContacts);
    _loadContacts();
    searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final hasPermission = await FlutterContacts.requestPermission();
      if (hasPermission) {
        setState(() {
          this.hasPermission = true;
        });
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        setState(() {
          allContacts = contacts;
          filteredContacts = allContacts;
          isLoading = false;
        });
      } else {
        setState(() {
          this.hasPermission = false;
          isLoading = false;
        });
        if (!widget.isPageView) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연락처 접근 권한이 필요합니다.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!widget.isPageView) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연락처 로드 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _filterContacts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredContacts = allContacts;
      } else {
        filteredContacts = allContacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final phones = contact.phones.map((p) => p.number).join(' ');
          return name.contains(query) || phones.contains(query);
        }).toList();
      }
    });
  }

  void _toggleContactSelection(Contact contact) {
    setState(() {
      if (selectedContacts.contains(contact)) {
        selectedContacts.remove(contact);
      } else {
        selectedContacts.add(contact);
      }
    });
    if (widget.onContactsChanged != null) {
      widget.onContactsChanged!(selectedContacts);
    }
  }

  String _getContactDisplayName(Contact contact) {
    return contact.displayName.isNotEmpty ? contact.displayName : '이름 없음';
  }

  String _getContactPhone(Contact contact) {
    final phones = contact.phones;
    if (phones.isNotEmpty) {
      return phones.first.number;
    }
    return '번호 없음';
  }

  void _proceedToMoodSelection() {
    if (widget.isPageView) {
      if (widget.onContactsChanged != null) {
        widget.onContactsChanged!(selectedContacts);
      }
    } else {
      Navigator.pop(context, selectedContacts);
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
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.selectedDate.month}월 ${widget.selectedDate.day}일 연락처',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '선택된 연락처: ${selectedContacts.length}명',
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

          // 검색바
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '연락처 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
            ),
          ),

          // 연락처 목록
          Expanded(
            child: !hasPermission
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contact_phone,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '연락처 접근 권한이 필요합니다',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadContacts,
                          child: const Text('권한 다시 요청'),
                        ),
                      ],
                    ),
                  )
                : isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : filteredContacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.contact_phone,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? '연락처가 없습니다'
                                      : '검색 결과가 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = filteredContacts[index];
                              final isSelected = selectedContacts.contains(contact);
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected 
                                      ? Colors.green 
                                      : Colors.grey.withOpacity(0.3),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
                                      : Text(
                                          _getContactDisplayName(contact).isNotEmpty
                                              ? _getContactDisplayName(contact)[0]
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                title: Text(_getContactDisplayName(contact)),
                                subtitle: Text(_getContactPhone(contact)),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : const Icon(
                                        Icons.radio_button_unchecked,
                                        color: Colors.grey,
                                      ),
                                onTap: () => _toggleContactSelection(contact),
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
                      onPressed: () {
                        Navigator.pop(context);
                        // _showPhotoSelectionModal(); // 상위에서 처리
                      },
                      child: const Text('이전'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedContacts.isEmpty ? null : _proceedToMoodSelection,
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