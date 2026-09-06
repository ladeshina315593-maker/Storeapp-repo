import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController _messageController =
      TextEditingController();

  bool _isSending = false;

  /// 0 = Community
  /// 1 = Unread
  /// 2 = Chats
  int _selectedFilter = 2;

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty ||
        _userId == null ||
        !_isConversation ||
        _isSending) {
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

      await messageRef.set({
        'senderId': _userId,
        'text': text,
        'type': 'text',
        'createdAt':
            FieldValue.serverTimestamp(),
        'read': false,
      });

      await chatRef.set(
        {
          'lastMessage': text,
          'lastMessageSenderId': _userId,
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
  // CHAT STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _chatStream() {
    return _firestore
        .collection('chats')
        .where(
          'participants',
          arrayContains: _userId,
        )
        .orderBy(
          'updatedAt',
          descending: true,
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
      // Community chats are identified by:
      // type == 'community'
      // OR isCommunity == true
      return chats.where((doc) {
        final data = doc.data();

        final type =
            data['type']?.toString().toLowerCase();

        final isCommunity =
            data['isCommunity'] == true;

        return type == 'community' ||
            isCommunity;
      }).toList();
    }

    // Unread chats are identified by:
    // unreadCount > 0
    // OR unread == true
    // OR unreadFor contains current user ID
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: pikkXBlack,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _userId == null
          ? _buildSignInState()
          : Column(
              children: [
                // FILTER BOX
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

                      final chats =
                          _filterChats(allChats);

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
                          90,
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
        0,
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

                final messages =
                    snapshot.data?.docs ??
                        [];

                if (messages.isEmpty) {
                  return _buildStartConversation();
                }

                return ListView.builder(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    10,
                  ),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (context, index) {
                    final message =
                        messages[index].data();

                    final isMine =
                        message[
                                'senderId'] ==
                            _userId;

                    return _messageBubble(
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
    Map<String, dynamic> message,
    bool isMine,
  ) {
    final text =
        message['text']?.toString() ?? '';

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 295,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 9,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? pikkXBlack
              : Colors.white.withOpacity(0.72),
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
                ? Colors.white.withOpacity(0.16)
                : Colors.white.withOpacity(0.9),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.035,
              ),
              blurRadius: 12,
              offset:
                  const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMine
                ? pikkXWhite
                : pikkXBlack,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
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
        child: _glass(
          radius: 22,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      _messageController,
                  textInputAction:
                      TextInputAction.send,
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
                      horizontal: 13,
                      vertical: 13,
                    ),
                  ),
                ),
              ),

              Material(
                color: pikkXBlack,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                child: InkWell(
                  onTap: _isSending
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
                          _isSending
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
                      BorderRadius.circular(10),
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