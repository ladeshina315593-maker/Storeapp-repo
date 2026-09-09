import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.chatId,
    this.otherUserName,
  });

  /// Null = Chat Inbox.
  /// A value = Individual conversation.
  final String? chatId;

  final String? otherUserName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color pikkXLightGrey = Color(0xFFE8E8E8);
  static const Color pikkXRed = Color(0xFFE53935);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  final ImagePicker _imagePicker =
      ImagePicker();

  final TextEditingController _messageController =
      TextEditingController();

  bool _isSending = false;
  bool _isSendingAttachment = false;

  /// 0 = Community
  /// 1 = Unread
  /// 2 = Chats
  int _selectedFilter = 2;

  /// Message currently being replied to.
  Map<String, dynamic>? _replyTo;

  User? get _currentUser => _auth.currentUser;

  String? get _userId => _currentUser?.uid;

  bool get _isConversation =>
      widget.chatId != null &&
      widget.chatId!.trim().isNotEmpty;

  CollectionReference<Map<String, dynamic>>
      get _messagesRef {
    if (!_isConversation) {
      throw StateError('No chat ID provided.');
    }

    return _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (_isConversation) {
      _markChatAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // MARK CHAT AS READ
  // ============================================================

  Future<void> _markChatAsRead() async {
    final uid = _userId;

    if (uid == null || !_isConversation) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .set(
        {
          'unreadFor': FieldValue.arrayRemove([uid]),
          'unread': false,
          'unreadCount': 0,
        },
        SetOptions(merge: true),
      );

      final unreadMessages = await _messagesRef
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in unreadMessages.docs) {
        final data = doc.data();

        if (data['senderId'] == uid) {
          continue;
        }

        batch.update(
          doc.reference,
          {
            'read': true,
          },
        );
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint(
        'Mark chat read error: $e',
      );
    }
  }

  // ============================================================
  // SEND TEXT MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty ||
        _userId == null ||
        !_isConversation ||
        _isSending ||
        _isSendingAttachment) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final chatRef = _firestore
          .collection('chats')
          .doc(widget.chatId);

      final messageRef =
          chatRef.collection('messages').doc();

      final messageData =
          <String, dynamic>{
        'senderId': _userId,
        'text': text,
        'type': 'text',
        'createdAt':
            FieldValue.serverTimestamp(),
        'read': false,
        'deleted': false,
        'reactions': <String, dynamic>{},
      };

      if (_replyTo != null) {
        messageData['replyTo'] = {
          'messageId':
              _replyTo!['messageId'],
          'senderId':
              _replyTo!['senderId'],
          'text':
              _replyTo!['text'] ?? '',
          'type':
              _replyTo!['type'] ?? 'text',
        };
      }

      await messageRef.set(messageData);

      await chatRef.set(
        {
          'lastMessage': text,
          'lastMessageSenderId':
              _userId,
          'updatedAt':
              FieldValue.serverTimestamp(),
          'participants':
              FieldValue.arrayUnion([
            _userId,
          ]),
        },
        SetOptions(merge: true),
      );

      _messageController.clear();

      if (mounted) {
        setState(() {
          _replyTo = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Send message error: $e',
      );
      debugPrint(
        'Stack trace: $stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Could not send message.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ============================================================
  // SEND IMAGE
  // ============================================================

  Future<void> _sendImage() async {
    if (_userId == null ||
        !_isConversation ||
        _isSending ||
        _isSendingAttachment) {
      return;
    }

    try {
      final picked =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (picked == null) {
        return;
      }

      setState(() {
        _isSendingAttachment = true;
      });

      final fileBytes =
          await picked.readAsBytes();

      final timestamp =
          DateTime.now().millisecondsSinceEpoch;

      final storageRef = _storage
          .ref()
          .child('chat_images')
          .child(widget.chatId!)
          .child(
            '${_userId}_$timestamp.jpg',
          );

      final uploadTask =
          await storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final imageUrl =
          await uploadTask.ref.getDownloadURL();

      final chatRef = _firestore
          .collection('chats')
          .doc(widget.chatId);

      final messageRef =
          chatRef.collection('messages').doc();

      await messageRef.set({
        'senderId': _userId,
        'text': '',
        'type': 'image',
        'imageUrl': imageUrl,
        'createdAt':
            FieldValue.serverTimestamp(),
        'read': false,
        'deleted': false,
        'reactions': <String, dynamic>{},
      });

      await chatRef.set(
        {
          'lastMessage': '📷 Image',
          'lastMessageSenderId':
              _userId,
          'updatedAt':
              FieldValue.serverTimestamp(),
          'participants':
              FieldValue.arrayUnion([
            _userId,
          ]),
        },
        SetOptions(merge: true),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Send image error: $e',
      );
      debugPrint(
        'Stack trace: $stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Could not send image.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAttachment = false;
        });
      }
    }
  }

  // ============================================================
  // SEND STICKER
  // ============================================================

  Future<void> _sendSticker(
    String sticker,
  ) async {
    if (_userId == null ||
        !_isConversation ||
        _isSending ||
        _isSendingAttachment) {
      return;
    }

    Navigator.of(context).pop();

    try {
      setState(() {
        _isSendingAttachment = true;
      });

      final chatRef = _firestore
          .collection('chats')
          .doc(widget.chatId);

      final messageRef =
          chatRef.collection('messages').doc();

      await messageRef.set({
        'senderId': _userId,
        'text': sticker,
        'type': 'sticker',
        'createdAt':
            FieldValue.serverTimestamp(),
        'read': false,
        'deleted': false,
        'reactions': <String, dynamic>{},
      });

      await chatRef.set(
        {
          'lastMessage': '🎨 Sticker',
          'lastMessageSenderId':
              _userId,
          'updatedAt':
              FieldValue.serverTimestamp(),
          'participants':
              FieldValue.arrayUnion([
            _userId,
          ]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Send sticker error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not send sticker.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAttachment = false;
        });
      }
    }
  }

  // ============================================================
  // CHAT STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _chatStream() {
    final uid = _userId;

    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where(
          'participants',
          arrayContains: uid,
        )
        .snapshots();
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  void _openChat(
    String chatId,
    String? name,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          otherUserName: name,
        ),
      ),
    );
  }

  // ============================================================
  // SORT CHAT LIST
  // ============================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _sortChats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        chats,
  ) {
    final sorted =
        List<QueryDocumentSnapshot<
            Map<String, dynamic>>>.from(
      chats,
    );

    sorted.sort(
      (a, b) {
        final aDate =
            _timestampToDate(
          a.data()['updatedAt'],
        );

        final bDate =
            _timestampToDate(
          b.data()['updatedAt'],
        );

        return bDate.compareTo(aDate);
      },
    );

    return sorted;
  }

  DateTime _timestampToDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  // ============================================================
  // FILTER CHAT LIST
  // ============================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterChats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        chats,
  ) {
    if (_selectedFilter == 2) {
      return chats;
    }

    if (_selectedFilter == 0) {
      return chats.where((doc) {
        final data = doc.data();

        final type =
            data['type']
                ?.toString()
                .toLowerCase();

        final isCommunity =
            data['isCommunity'] == true;

        return type == 'community' ||
            isCommunity;
      }).toList();
    }

    return chats.where((doc) {
      final data = doc.data();

      final unreadCount =
          data['unreadCount'];

      final hasUnreadCount =
          unreadCount is num &&
          unreadCount > 0;

      final unread =
          data['unread'] == true;

      final unreadFor =
          data['unreadFor'];

      final unreadForUser =
          unreadFor is List &&
          _userId != null &&
          unreadFor.contains(_userId);

      return hasUnreadCount ||
          unread ||
          unreadForUser;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!_isConversation) {
      return _buildInbox();
    }

    return _buildConversation();
  }

  // ============================================================
  // CHAT INBOX
  // ============================================================

  Widget _buildInbox() {
    return Scaffold(
      backgroundColor: pikkXBackground,
      body: _userId == null
          ? _buildSignInState()
          : Column(
              children: [
                _buildFilterBox(),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<
                          Map<String, dynamic>>>(
                    stream: _chatStream(),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(
                            color: pikkXBlack,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        debugPrint(
                          'Chat stream error: '
                          '${snapshot.error}',
                        );

                        return _buildErrorState();
                      }

                      final allChats =
                          snapshot.data?.docs ?? [];

                      final filteredChats =
                          _filterChats(allChats);

                      final chats =
                          _sortChats(
                        filteredChats,
                      );

                      if (chats.isEmpty) {
                        if (_selectedFilter == 0) {
                          return _buildFilterEmptyState(
                            'No community chats',
                            'Community conversations will appear here.',
                            Icons.groups_rounded,
                          );
                        }

                        if (_selectedFilter == 1) {
                          return _buildFilterEmptyState(
                            'No unread chats',
                            'You are all caught up.',
                            Icons.mark_chat_read_rounded,
                          );
                        }

                        return _buildEmptyInbox();
                      }

                      return ListView.builder(
                        physics:
                            const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          100,
                        ),
                        itemCount: chats.length,
                        itemBuilder:
                            (context, index) {
                          final doc =
                              chats[index];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 9,
                            ),
                            child:
                                _buildChatTile(
                              doc.id,
                              doc.data(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // GLASS FILTER BOX
  // ============================================================

  Widget _buildFilterBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: _glass(
        radius: 18,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _filterButton(
              label: 'Community',
              index: 0,
              icon: Icons.groups_rounded,
            ),
            _filterButton(
              label: 'Unread',
              index: 1,
              icon: Icons.mark_email_unread_rounded,
            ),
            _filterButton(
              label: 'Chats',
              index: 2,
              icon: Icons.chat_bubble_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final selected =
        _selectedFilter == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedFilter == index) {
            return;
          }

          setState(() {
            _selectedFilter = index;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 39,
          decoration: BoxDecoration(
            color: selected
                ? pikkXBlack
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? pikkXWhite
                    : pikkXGrey,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? pikkXWhite
                        : pikkXGrey,
                    fontSize: 10.5,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHAT TILE
  // ============================================================

  Widget _buildChatTile(
    String chatId,
    Map<String, dynamic> data,
  ) {
    final name =
        data['otherUserName']?.toString();

    final lastMessage =
        data['lastMessage']
                ?.toString()
                .trim() ??
            'Start a conversation';

    final displayName =
        name == null || name.isEmpty
            ? 'Chat'
            : name;

    final unreadCount =
        _getUnreadCount(data);

    final isCommunity =
        data['type']
                ?.toString()
                .toLowerCase() ==
            'community' ||
        data['isCommunity'] == true;

    return _glass(
      radius: 21,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openChat(
              chatId,
              name,
            );
          },
          borderRadius:
              BorderRadius.circular(21),
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: Row(
              children: [
                _chatAvatar(
                  displayName,
                  isCommunity: isCommunity,
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                color: pikkXBlack,
                                fontSize: 14,
                                fontWeight:
                                    unreadCount > 0
                                        ? FontWeight.w900
                                        : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            _unreadBadge(
                              unreadCount,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pikkXGrey,
                          fontSize: 11.5,
                          fontWeight:
                              unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: pikkXWhite,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  int _getUnreadCount(
    Map<String, dynamic> data,
  ) {
    final value =
        data['unreadCount'];

    if (value is num) {
      return value.toInt();
    }

    if (data['unread'] == true) {
      return 1;
    }

    final unreadFor =
        data['unreadFor'];

    if (unreadFor is List &&
        _userId != null &&
        unreadFor.contains(_userId)) {
      return 1;
    }

    return 0;
  }

  Widget _unreadBadge(
    int count,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        minWidth: 20,
      ),
      height: 20,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99
            ? '99+'
            : count.toString(),
        style: const TextStyle(
          color: pikkXWhite,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // CONVERSATION
  // ============================================================

  Widget _buildConversation() {
    return Scaffold(
      backgroundColor: pikkXBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme:
            const IconThemeData(
          color: pikkXBlack,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _smallAvatar(),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                widget.otherUserName ??
                    'Chat',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: pikkXBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _messagesRef
                  .orderBy(
                    'createdAt',
                    descending: false,
                  )
                  .snapshots(),
              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color: pikkXBlack,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'Messages stream error: '
                    '${snapshot.error}',
                  );

                  return _buildErrorState();
                }

                final rawMessages =
                    snapshot.data?.docs ??
                        [];

                final messages =
                    rawMessages.where((doc) {
                  final data =
                      doc.data();

                  final deletedFor =
                      data['deletedFor'];

                  if (deletedFor is List &&
                      _userId != null &&
                      deletedFor.contains(
                        _userId,
                      )) {
                    return false;
                  }

                  return true;
                }).toList();

                if (messages.isEmpty) {
                  return _buildStartConversation();
                }

                return ListView.builder(
                  reverse: false,
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    18,
                  ),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (context, index) {
                    final doc =
                        messages[index];

                    final message =
                        doc.data();

                    final isMine =
                        message[
                                'senderId'] ==
                            _userId;

                    return _messageBubble(
                      doc,
                      message,
                      isMine,
                    );
                  },
                );
              },
            ),
          ),
          _messageInput(),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _messageBubble(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
    Map<String, dynamic> message,
    bool isMine,
  ) {
    final type =
        message['type']
                ?.toString()
                .toLowerCase() ??
            'text';

    final text =
        message['text']?.toString() ?? '';

    final isDeleted =
        message['deleted'] == true;

    final replyTo =
        _asMap(message['replyTo']);

    final reactions =
        _asMap(message['reactions']);

    return GestureDetector(
      onLongPress: isDeleted
          ? null
          : () {
              _showMessageActions(
                doc,
                message,
                isMine,
              );
            },
      child: Align(
        alignment: isMine
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth: 310,
          ),
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: Column(
            crossAxisAlignment:
                isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            children: [
              _buildReplyPreview(
                replyTo,
                isMine,
              ),

              Container(
                padding:
                    type == 'image'
                        ? const EdgeInsets.all(6)
                        : const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 11,
                          ),
                decoration: BoxDecoration(
                  color: isMine
                      ? pikkXBlack
                      : Colors.white
                          .withOpacity(0.72),
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        const Radius.circular(20),
                    topRight:
                        const Radius.circular(20),
                    bottomLeft:
                        Radius.circular(
                      isMine ? 20 : 5,
                    ),
                    bottomRight:
                        Radius.circular(
                      isMine ? 5 : 20,
                    ),
                  ),
                  border: Border.all(
                    color: isMine
                        ? Colors.white
                            .withOpacity(
                            0.16,
                          )
                        : Colors.white
                            .withOpacity(
                            0.9,
                          ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withOpacity(
                        0.035,
                      ),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildMessageContent(
                  type: type,
                  text: text,
                  message: message,
                  isMine: isMine,
                  isDeleted: isDeleted,
                ),
              ),

              if (reactions.isNotEmpty)
                _buildReactions(
                  reactions,
                  doc.id,
                  isMine,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE CONTENT
  // ============================================================

  Widget _buildMessageContent({
    required String type,
    required String text,
    required Map<String, dynamic> message,
    required bool isMine,
    required bool isDeleted,
  }) {
    if (isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 15,
            color: isMine
                ? Colors.white54
                : pikkXGrey,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Message deleted',
              style: TextStyle(
                color: isMine
                    ? Colors.white60
                    : pikkXGrey,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    if (type == 'image') {
      final imageUrl =
          message['imageUrl']
              ?.toString();

      if (imageUrl == null ||
          imageUrl.isEmpty) {
        return const Text(
          'Image unavailable',
          style: TextStyle(
            color: pikkXGrey,
            fontSize: 13,
          ),
        );
      }

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(17),
        child: Image.network(
          imageUrl,
          width: 240,
          height: 240,
          fit: BoxFit.cover,
          loadingBuilder:
              (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress ==
                null) {
              return child;
            }

            return const SizedBox(
              width: 240,
              height: 240,
              child: Center(
                child:
                    CircularProgressIndicator(
                  color: pikkXBlack,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              width: 240,
              height: 240,
              color: pikkXLightGrey,
              alignment:
                  Alignment.center,
              child: const Icon(
                Icons
                    .broken_image_outlined,
                color: pikkXGrey,
                size: 35,
              ),
            );
          },
        ),
      );
    }

    if (type == 'sticker') {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 54,
          height: 1,
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: isMine
            ? pikkXWhite
            : pikkXBlack,
        fontSize: 14,
        height: 1.35,
      ),
    );
  }

  // ============================================================
  // REPLY PREVIEW INSIDE MESSAGE
  // ============================================================

  Widget _buildReplyPreview(
    Map<String, dynamic>? reply,
    bool isMine,
  ) {
    if (reply == null) {
      return const SizedBox.shrink();
    }

    final replyText =
        reply['text']?.toString() ??
            '';

    final replyType =
        reply['type']?.toString() ??
            'text';

    return Container(
      width: 260,
      margin:
          const EdgeInsets.only(
        bottom: 5,
      ),
      padding:
          const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isMine
            ? pikkXBlack.withOpacity(0.08)
            : Colors.white.withOpacity(0.55),
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: isMine
              ? Colors.white
                  .withOpacity(0.1)
              : Colors.white
                  .withOpacity(0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: isMine
                  ? pikkXWhite
                  : pikkXBlack,
              borderRadius:
                  BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              replyType == 'image'
                  ? '📷 Image'
                  : replyText.isEmpty
                      ? 'Message'
                      : replyText,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: isMine
                    ? pikkXWhite
                    : pikkXBlack,
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REACTIONS DISPLAY
  // ============================================================

  Widget _buildReactions(
    Map<String, dynamic> reactions,
    String messageId,
    bool isMine,
  ) {
    final emojis =
        reactions.values
            .map(
              (value) =>
                  value?.toString() ?? '',
            )
            .where(
              (value) => value.isNotEmpty,
            )
            .toSet()
            .toList();

    if (emojis.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        _showReactionPicker(
          messageId,
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          top: 3,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white
              .withOpacity(0.92),
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color:
                Colors.white.withOpacity(
              0.95,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.04,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            ...emojis
                .take(4)
                .map(
                  (emoji) => Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 2,
                    ),
                    child: Text(
                      emoji,
                      style:
                          const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LONG-PRESS MESSAGE ACTIONS
  // ============================================================

  void _showMessageActions(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
    Map<String, dynamic> message,
    bool isMine,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: _glass(
              radius: 27,
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      color: pikkXGrey
                          .withOpacity(0.45),
                      borderRadius:
                          BorderRadius.circular(
                        5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _quickReactionRow(
                    doc.id,
                  ),

                  const Divider(
                    height: 18,
                  ),

                  _actionTile(
                    icon:
                        Icons.reply_rounded,
                    label: 'Reply',
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                      );
                      _setReplyTo(
                        doc.id,
                        message,
                      );
                    },
                  ),

                  if ((message['text']
                              ?.toString()
                              .isNotEmpty ??
                          false))
                    _actionTile(
                      icon:
                          Icons.copy_rounded,
                      label: 'Copy',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _copyMessage(
                          message['text']
                              ?.toString() ??
                              '',
                        );
                      },
                    ),

                  _actionTile(
                    icon:
                        Icons.add_reaction_outlined,
                    label: 'React',
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                      );
                      _showReactionPicker(
                        doc.id,
                      );
                    },
                  ),

                  _actionTile(
                    icon:
                        Icons.delete_outline_rounded,
                    label: 'Delete for me',
                    onTap: () async {
                      Navigator.pop(
                        sheetContext,
                      );
                      await _deleteForMe(
                        doc.id,
                      );
                    },
                  ),

                  if (isMine)
                    _actionTile(
                      icon:
                          Icons.delete_forever_rounded,
                      label:
                          'Delete for everyone',
                      destructive: true,
                      onTap: () async {
                        Navigator.pop(
                          sheetContext,
                        );
                        await _deleteForEveryone(
                          doc.id,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // QUICK REACTIONS
  // ============================================================

  Widget _quickReactionRow(
    String messageId,
  ) {
    const reactions = [
      '❤️',
      '😂',
      '😮',
      '😢',
      '👍',
      '🔥',
    ];

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,
      children: reactions.map(
        (emoji) {
          return GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await _setReaction(
                messageId,
                emoji,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.55),
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.85),
                ),
              ),
              child: Text(
                emoji,
                style:
                    const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // REACTION PICKER
  // ============================================================

  void _showReactionPicker(
    String messageId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        const reactions = [
          '❤️',
          '😂',
          '😮',
          '😢',
          '👍',
          '🔥',
          '👏',
          '😍',
        ];

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: _glass(
              radius: 27,
              padding:
                  const EdgeInsets.all(14),
              child: Wrap(
                alignment:
                    WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children:
                    reactions.map(
                  (emoji) {
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(
                          sheetContext,
                        );

                        await _setReaction(
                          messageId,
                          emoji,
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment:
                            Alignment.center,
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(
                            0.60,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style:
                              const TextStyle(
                            fontSize: 25,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SET REACTION
  // ============================================================

  Future<void> _setReaction(
    String messageId,
    String emoji,
  ) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    try {
      final messageRef =
          _messagesRef.doc(messageId);

      await _firestore.runTransaction(
        (transaction) async {
          final snapshot =
              await transaction.get(
            messageRef,
          );

          if (!snapshot.exists) {
            return;
          }

          final data =
              snapshot.data() ?? {};

          final currentReactions =
              <String, dynamic>{
            ..._asMap(
              data['reactions'],
            ),
          };

          final existing =
              currentReactions[uid];

          if (existing == emoji) {
            currentReactions.remove(uid);
          } else {
            currentReactions[uid] = emoji;
          }

          transaction.update(
            messageRef,
            {
              'reactions':
                  currentReactions,
            },
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Reaction error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not update reaction.',
        );
      }
    }
  }

  // ============================================================
  // COPY MESSAGE
  // ============================================================

  Future<void> _copyMessage(
    String text,
  ) async {
    if (text.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (mounted) {
      _showMessage(
        'Message copied.',
      );
    }
  }

  // ============================================================
  // REPLY
  // ============================================================

  void _setReplyTo(
    String messageId,
    Map<String, dynamic> message,
  ) {
    setState(() {
      _replyTo = {
        'messageId': messageId,
        'senderId':
            message['senderId'],
        'text':
            message['text'] ?? '',
        'type':
            message['type'] ?? 'text',
      };
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
    });
  }

  // ============================================================
  // DELETE FOR ME
  // ============================================================

  Future<void> _deleteForMe(
    String messageId,
  ) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    try {
      await _messagesRef
          .doc(messageId)
          .set(
        {
          'deletedFor':
              FieldValue.arrayUnion([
            uid,
          ]),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        _showMessage(
          'Message deleted for you.',
        );
      }
    } catch (e) {
      debugPrint(
        'Delete for me error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not delete message.',
        );
      }
    }
  }

  // ============================================================
  // DELETE FOR EVERYONE
  // ============================================================

  Future<void> _deleteForEveryone(
    String messageId,
  ) async {
    try {
      await _messagesRef
          .doc(messageId)
          .set(
        {
          'deleted': true,
          'text': 'Message deleted',
          'imageUrl': null,
          'deletedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        _showMessage(
          'Message deleted for everyone.',
        );
      }
    } catch (e) {
      debugPrint(
        'Delete for everyone error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not delete message.',
        );
      }
    }
  }

  // ============================================================
  // MESSAGE INPUT
  // ============================================================

  Widget _messageInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          12,
          6,
          12,
          12,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            if (_replyTo != null)
              _buildReplyComposer(),

            _glass(
              radius: 22,
              padding:
                  const EdgeInsets.all(4),
              child: Row(
                children: [
                  _inputActionButton(
                    icon:
                        Icons.add_rounded,
                    onTap:
                        _isSending ||
                                _isSendingAttachment
                            ? null
                            : _showAttachmentOptions,
                  ),

                  Expanded(
                    child: TextField(
                      controller:
                          _messageController,
                      textInputAction:
                          TextInputAction.send,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      style:
                          const TextStyle(
                        color: pikkXBlack,
                        fontSize: 14,
                      ),
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Write a message...',
                        hintStyle:
                            TextStyle(
                          color:
                              pikkXGrey,
                        ),
                        border:
                            InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),

                  _inputActionButton(
                    icon:
                        Icons.emoji_emotions_outlined,
                    onTap:
                        _isSending ||
                                _isSendingAttachment
                            ? null
                            : _showStickerPicker,
                  ),

                  const SizedBox(width: 3),

                  Material(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    child: InkWell(
                      onTap:
                          (_isSending ||
                                  _isSendingAttachment)
                              ? null
                              : _sendMessage,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child:
                              (_isSending ||
                                      _isSendingAttachment)
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            pikkXWhite,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .send_rounded,
                                      color:
                                          pikkXWhite,
                                      size: 19,
                                    ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REPLY COMPOSER
  // ============================================================

  Widget _buildReplyComposer() {
    final replyType =
        _replyTo!['type']
                ?.toString() ??
            'text';

    final replyText =
        _replyTo!['text']
                ?.toString() ??
            '';

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 6,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.82),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.95,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: pikkXBlack,
              borderRadius:
                  BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Replying to message',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyType == 'image'
                      ? '📷 Image'
                      : replyText.isEmpty
                          ? 'Message'
                          : replyText,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: pikkXGrey,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(
              Icons.close_rounded,
              color: pikkXBlack,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputActionButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 20,
      icon: Icon(
        icon,
        color: onTap == null
            ? pikkXGrey.withOpacity(0.4)
            : pikkXBlack,
        size: 22,
      ),
    );
  }

  // ============================================================
  // ATTACHMENT OPTIONS
  // ============================================================

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: _glass(
              radius: 27,
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                14,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  _actionTile(
                    icon:
                        Icons.photo_library_outlined,
                    label: 'Send image',
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                      );
                      _sendImage();
                    },
                  ),
                  _actionTile(
                    icon:
                        Icons.sticky_note_2_outlined,
                    label: 'Send sticker',
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                      );
                      _showStickerPicker();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STICKER PICKER
  // ============================================================

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        const stickers = [
          '😂',
          '❤️',
          '😍',
          '🔥',
          '😎',
          '🥰',
          '👏',
          '✨',
          '🎉',
          '🙌',
          '👍',
          '😮',
          '🤍',
          '💯',
          '🫶',
          '😄',
          '😁',
          '🥹',
          '😅',
          '🤩',
        ];

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: _glass(
              radius: 27,
              padding:
                  const EdgeInsets.all(15),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount:
                    stickers.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder:
                    (context, index) {
                  final sticker =
                      stickers[index];

                  return GestureDetector(
                    onTap: () {
                      _sendSticker(
                        sticker,
                      );
                    },
                    child: Container(
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.58,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                        border: Border.all(
                          color: Colors.white
                              .withOpacity(
                            0.9,
                          ),
                        ),
                      ),
                      alignment:
                          Alignment.center,
                      child: Text(
                        sticker,
                        style:
                            const TextStyle(
                          fontSize: 27,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ACTION TILE
  // ============================================================

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color: destructive
                      ? pikkXRed
                          .withOpacity(0.10)
                      : pikkXBlack
                          .withOpacity(0.055),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: destructive
                      ? pikkXRed
                      : pikkXBlack,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: destructive
                        ? pikkXRed
                        : pikkXBlack,
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY INBOX
  // ============================================================

  Widget _buildEmptyInbox() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(22),
        child: _glass(
          radius: 28,
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _largeChatIcon(),
              const SizedBox(height: 15),
              const Text(
                'No chats yet',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Your conversations with sellers and support will appear here.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER EMPTY
  // ============================================================

  Widget _buildFilterEmptyState(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(22),
        child: _glass(
          radius: 27,
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color:
                      pikkXBlack.withOpacity(
                    0.055,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: pikkXBlack,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: pikkXBlack,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Widget _buildSignInState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(22),
        child: _glass(
          radius: 28,
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _largeChatIcon(),
              const SizedBox(height: 15),
              const Text(
                'Sign in to use Chat',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Sign in to see your conversations and messages.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // START CONVERSATION
  // ============================================================

  Widget _buildStartConversation() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            _largeChatIcon(),
            const SizedBox(height: 15),
            const Text(
              'Start the conversation',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: pikkXBlack,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Send a message below to get started.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: pikkXGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: _glass(
          radius: 25,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                size: 44,
                color: pikkXBlack,
              ),
              const SizedBox(height: 11),
              const Text(
                'Could not load chats',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please check your connection and try again.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AVATARS
  // ============================================================

  Widget _chatAvatar(
    String name, {
    bool isCommunity = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: pikkXBlack,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Colors.white.withOpacity(0.9),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          isCommunity
              ? Icons.groups_rounded
              : Icons.person_rounded,
          color: pikkXWhite,
          size: 22,
        ),
      ),
    );
  }

  Widget _smallAvatar() {
    return _chatAvatar(
      widget.otherUserName ?? 'Chat',
    );
  }

  Widget _largeChatIcon() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.15,
            ),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: pikkXWhite,
        size: 37,
      ),
    );
  }

  // ============================================================
  // GLASS FIXTURE
  // ============================================================

  Widget _glass({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(
              0.70,
            ),
            borderRadius:
                BorderRadius.circular(radius),
            border: Border.all(
              color:
                  Colors.white.withOpacity(
                0.92,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  0.045,
                ),
                blurRadius: 20,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // MAP HELPERS
  // ============================================================

  Map<String, dynamic>? _asMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: pikkXWhite,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: pikkXWhite,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: pikkXBlack,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          duration:
              const Duration(seconds: 2),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }
}