import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String? otherUserName;

  const ChatPage({
    super.key,
    required this.chatId,
    this.otherUserName,
  });

  @override
  State<ChatPage> createState() =>
      _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController
      _messageController =
      TextEditingController();

  bool isSending = false;

  String? get userId =>
      _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>
      get messagesRef {
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

  Future<void> _sendMessage() async {
    final text =
        _messageController.text.trim();

    if (text.isEmpty ||
        userId == null ||
        isSending) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final messageRef =
          messagesRef.doc();

      await messageRef.set({
        'senderId': userId,
        'text': text,
        'type': 'text',
        'createdAt':
            FieldValue.serverTimestamp(),
        'read': false,
      });

      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .set({
        'participants':
            FieldValue.arrayUnion([
          userId,
        ]),
        'lastMessage': text,
        'lastMessageSenderId':
            userId,
        'updatedAt':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _messageController.clear();
    } catch (e) {
      debugPrint(
        'Send message error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.otherUserName ??
              'Chat',
          style: const TextStyle(
            color:
                Color(0xFF1D2635),
            fontSize: 20,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color:
              Color(0xFF1D2635),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: messagesRef
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
                      color:
                          Color(0xFFB98BEF),
                    ),
                  );
                }

                final messages =
                    snapshot.data?.docs ??
                        [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start the conversation',
                      style: TextStyle(
                        color:
                            Color(0xFF797878),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(16),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (context, index) {
                    final message =
                        messages[index]
                            .data();

                    final isMine =
                        message[
                                'senderId'] ==
                            userId;

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

  Widget _messageBubble(
    Map<String, dynamic> message,
    bool isMine,
  ) {
    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 290,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration:
            BoxDecoration(
          color: isMine
              ? const Color(
                  0xFFB98BEF,
                )
              : Colors.white
                  .withOpacity(0.78),
          borderRadius:
              BorderRadius.circular(19),
          border: isMine
              ? null
              : Border.all(
                  color: Colors.white
                      .withOpacity(0.9),
                ),
        ),
        child: Text(
          message['text']
                  ?.toString() ??
              '',
          style: TextStyle(
            color: isMine
                ? Colors.white
                : const Color(
                    0xFF1D2635,
                  ),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _messageInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          12,
        ),
        child: _glass(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      _messageController,
                  textInputAction:
                      TextInputAction.send,
                  onSubmitted: (_) =>
                      _sendMessage(),
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Write a message...',
                    hintStyle:
                        TextStyle(
                      color:
                          Color(0xFFA1A3A6),
                    ),
                    border:
                        InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: isSending
                    ? null
                    : _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color:
                      Color(0xFF8F62D9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glass({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          decoration:
              BoxDecoration(
            color:
                Colors.white.withOpacity(0.76),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.88),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}