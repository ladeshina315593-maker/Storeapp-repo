import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/themes/theme.dart';

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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController _messageController =
      TextEditingController();

  bool _isSending = false;

  double _addButtonRight = 18.0;
  double _addButtonBottom = 88.0;

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
      final chatRef =
          _firestore.collection('chats').doc(widget.chatId);

      final messageRef =
          chatRef.collection('messages').doc();

      await messageRef.set({
        'senderId': _userId,
        'text': text,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      await chatRef.set(
        {
          'lastMessage': text,
          'lastMessageSenderId': _userId,
          'updatedAt': FieldValue.serverTimestamp(),
          'participants': FieldValue.arrayUnion([
            _userId,
          ]),
        },
        SetOptions(merge: true),
      );

      _messageController.clear();
    } catch (e) {
      debugPrint('Send message error: $e');

      if (mounted) {
        _showMessage('Could not send message.');
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
  // CHAT INBOX
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _chatStream() {
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
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: AppTheme.darkText,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _userId == null
          ? _buildSignInState()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.pikkXNavy,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'Chat stream error: ${snapshot.error}',
                  );

                  return _buildErrorState();
                }

                final chats = snapshot.data?.docs ?? [];

                return Stack(
                  children: [
                    ListView(
                      physics:
                          const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        5,
                        16,
                        120,
                      ),
                      children: [
                        _buildPikkXWelcomeChat(),

                        const SizedBox(height: 12),

                        ...chats.map((doc) {
                          final data = doc.data();

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _buildChatTile(
                              doc.id,
                              data,
                            ),
                          );
                        }),
                      ],
                    ),

                    _buildMovableAddButton(),
                  ],
                );
              },
            ),
    );
  }

  // ============================================================
  // PIKKX WELCOME CHAT
  // ============================================================

  Widget _buildPikkXWelcomeChat() {
    return _glass(
      radius: 23,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showMessage(
              'PikkX support chat will be available soon.',
            );
          },
          borderRadius: BorderRadius.circular(23),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.pikkXBlack,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.pikkXNavy
                          .withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 13),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'pikkx',
                        style: TextStyle(
                          color: AppTheme.darkText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Welcome to pikkx! 👋 We’re here to help with your shopping experience.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 13,
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
  // MOVABLE ADD CHAT BUTTON
  // ============================================================

  Widget _buildMovableAddButton() {
    return Positioned(
      right: _addButtonRight,
      bottom: _addButtonBottom,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _addButtonRight -= details.delta.dx;
            _addButtonBottom -= details.delta.dy;

            final size = MediaQuery.of(context).size;

            final maxRight = size.width - 76.0;
            final maxBottom = size.height - 150.0;

            _addButtonRight = _addButtonRight
                .clamp(
                  8.0,
                  maxRight > 8.0 ? maxRight : 8.0,
                )
                .toDouble();

            _addButtonBottom = _addButtonBottom
                .clamp(
                  8.0,
                  maxBottom > 8.0 ? maxBottom : 8.0,
                )
                .toDouble();
          });
        },
        onTap: () {
          _showMessage('New chat coming soon.');
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppTheme.pikkXBlack,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.pikkXNavy.withOpacity(0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 30,
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
    final name = data['otherUserName']?.toString();

    final lastMessage =
        data['lastMessage']?.toString().trim() ??
        'Start a conversation';

    final displayName =
        name == null || name.isEmpty ? 'Chat' : name;

    return _glass(
      radius: 23,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openChat(
              chatId,
              name,
            );
          },
          borderRadius: BorderRadius.circular(23),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                _chatAvatar(displayName),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.darkText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 13,
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
  // CONVERSATION
  // ============================================================

  Widget _buildConversation() {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(
          color: AppTheme.darkText,
        ),
        title: Row(
          children: [
            _smallAvatar(),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                widget.otherUserName ?? 'Chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 19,
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
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesRef
                  .orderBy(
                    'createdAt',
                    descending: false,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.pikkXNavy,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final messages =
                    snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return _buildStartConversation();
                }

                return ListView.builder(
                  physics:
                      const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data();

                    final isMine =
                        message['senderId'] == _userId;

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
    final text = message['text']?.toString() ?? '';

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(maxWidth: 295),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? AppTheme.pikkXBlack
              : Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(
              isMine ? 20 : 5,
            ),
            bottomRight: Radius.circular(
              isMine ? 5 : 20,
            ),
          ),
          border: Border.all(
            color: isMine
                ? AppTheme.pikkXNavy.withOpacity(0.35)
                : Colors.white.withOpacity(0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMine
                ? Colors.white
                : AppTheme.darkText,
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
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          12,
        ),
        child: _glass(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 4,
              right: 5,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction:
                        TextInputAction.send,
                    onSubmitted: (_) {
                      _sendMessage();
                    },
                    style: const TextStyle(
                      color: AppTheme.darkText,
                      fontSize: 14,
                    ),
                    decoration:
                        const InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: TextStyle(
                        color: AppTheme.mutedText,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                Material(
                  color: AppTheme.pikkXBlack,
                  borderRadius:
                      BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _isSending
                        ? null
                        : _sendMessage,
                    borderRadius:
                        BorderRadius.circular(16),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
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
      ),
    );
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Widget _buildSignInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _glass(
          radius: 30,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _largeChatIcon(),

                const SizedBox(height: 18),

                const Text(
                  'Sign in to use Chat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Sign in to see your conversations and messages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 20),

                _blackButton(
                  text: 'Sign In',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/sign-in',
                    );
                  },
                ),
              ],
            ),
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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _largeChatIcon(),

            const SizedBox(height: 16),

            const Text(
              'Start the conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Send a message below to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedText,
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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.pikkXNavy,
            ),

            const SizedBox(height: 12),

            const Text(
              'Could not load chats',
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATARS
  // ============================================================

  Widget _chatAvatar(String name) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.pikkXBlack,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.pikkXNavy.withOpacity(0.30),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          name.isEmpty
              ? 'C'
              : name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _smallAvatar() {
    final name =
        widget.otherUserName ?? 'Chat';

    return _chatAvatar(name);
  }

  Widget _largeChatIcon() {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppTheme.pikkXBlack,
        borderRadius:
            BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.pikkXNavy.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: Colors.white,
        size: 39,
      ),
    );
  }

  // ============================================================
  // BLACK BUTTON
  // ============================================================

  Widget _blackButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: AppTheme.pikkXBlack,
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color:
                  AppTheme.pikkXNavy.withOpacity(0.30),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS FIXTURE
  // ============================================================

  Widget _glass({
    required Widget child,
    double radius = 24,
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
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.70),
            borderRadius:
                BorderRadius.circular(radius),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.90),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.055),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color:
                    AppTheme.pikkXNavy.withOpacity(0.045),
                blurRadius: 28,
                spreadRadius: 1,
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.pikkXBlack,
          behavior:
              SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      );
  }
}

