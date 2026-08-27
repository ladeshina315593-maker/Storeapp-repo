import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository({
    FirebaseFirestore firestore,
    FirebaseAuth auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Current authenticated user's UID.
  String get _userId {
    final User user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    return user.uid;
  }

  /// Chats belonging to the current user.
  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  /// Get one chat reference.
  DocumentReference<Map<String, dynamic>> _chat(
    String chatId,
  ) {
    return _chats.doc(chatId);
  }

  /// Get messages for a chat.
  CollectionReference<Map<String, dynamic>> _messages(
    String chatId,
  ) {
    return _chat(chatId).collection('messages');
  }

  // ============================================================
  // CHAT LIST
  // ============================================================

  /// Get all chats where the current user is a participant.
  Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _chats
              .where(
                'participants',
                arrayContains: _userId,
              )
              .orderBy(
                'updatedAt',
                descending: true,
              )
              .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  /// Real-time chat list.
  Stream<List<Map<String, dynamic>>> chatsStream() {
    return _chats
        .where(
          'participants',
          arrayContains: _userId,
        )
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // ============================================================
  // CREATE / GET CHAT
  // ============================================================

  /// Create a private chat between the current user and another user.
  ///
  /// Returns the chat ID.
  Future<String> createChat({
    required String otherUserId,
    String otherUserName = '',
    String otherUserImage = '',
  }) async {
    try {
      if (otherUserId == _userId) {
        throw Exception(
          'You cannot create a chat with yourself.',
        );
      }

      final QuerySnapshot<Map<String, dynamic>> existing =
          await _chats
              .where(
                'participants',
                arrayContains: _userId,
              )
              .get();

      for (final doc in existing.docs) {
        final data = doc.data();
        final List<dynamic> participants =
            data['participants'] ?? [];

        if (participants.contains(otherUserId) &&
            participants.length == 2) {
          return doc.id;
        }
      }

      final DocumentReference<Map<String, dynamic>> chat =
          await _chats.add({
        'participants': [
          _userId,
          otherUserId,
        ],
        'participantInfo': {
          _userId: {
            'userId': _userId,
          },
          otherUserId: {
            'userId': otherUserId,
            'name': otherUserName,
            'imageUrl': otherUserImage,
          },
        },
        'lastMessage': '',
        'lastMessageSenderId': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return chat.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  /// Get one chat by ID.
  Future<Map<String, dynamic>?> getChat(
    String chatId,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _chat(chatId).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      final List<dynamic> participants =
          data['participants'] ?? [];

      if (!participants.contains(_userId)) {
        throw Exception('You do not have access to this chat.');
      }

      return {
        'id': snapshot.id,
        ...data,
      };
    } catch (e) {
      throw Exception('Failed to load chat: $e');
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  /// Get messages from a chat.
  Future<List<Map<String, dynamic>>> getMessages(
    String chatId,
  ) async {
    try {
      await _verifyChatAccess(chatId);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _messages(chatId)
              .orderBy(
                'createdAt',
                descending: false,
              )
              .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Real-time messages for a chat.
  Stream<List<Map<String, dynamic>>> messagesStream(
    String chatId,
  ) {
    return _messages(chatId)
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Send a text message.
  Future<String> sendMessage({
    required String chatId,
    required String text,
  }) async {
    try {
      await _verifyChatAccess(chatId);

      final String message = text.trim();

      if (message.isEmpty) {
        throw Exception('Message cannot be empty.');
      }

      final DocumentReference<Map<String, dynamic>> messageRef =
          await _messages(chatId).add({
        'senderId': _userId,
        'text': message,
        'type': 'text',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _chat(chatId).update({
        'lastMessage': message,
        'lastMessageSenderId': _userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return messageRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // ============================================================
  // MESSAGE STATUS
  // ============================================================

  /// Mark a message as read.
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _verifyChatAccess(chatId);

      await _messages(chatId).doc(messageId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(
        'Failed to mark message as read: $e',
      );
    }
  }

  /// Mark all messages from another user as read.
  Future<void> markAllMessagesAsRead(
    String chatId,
  ) async {
    try {
      await _verifyChatAccess(chatId);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _messages(chatId)
              .where(
                'isRead',
                isEqualTo: false,
              )
              .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['senderId'] != _userId) {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception(
        'Failed to mark messages as read: $e',
      );
    }
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  /// Delete a message sent by the current user.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _verifyChatAccess(chatId);

      final DocumentSnapshot<Map<String, dynamic>> message =
          await _messages(chatId).doc(messageId).get();

      if (!message.exists) {
        throw Exception('Message does not exist.');
      }

      final data = message.data() ?? {};

      if (data['senderId'] != _userId) {
        throw Exception(
          'You can only delete your own messages.',
        );
      }

      await _messages(chatId).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // ============================================================
  // UNREAD MESSAGES
  // ============================================================

  /// Get unread messages for a chat.
  Future<int> getUnreadCount(
    String chatId,
  ) async {
    try {
      await _verifyChatAccess(chatId);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _messages(chatId)
              .where(
                'isRead',
                isEqualTo: false,
              )
              .get();

      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['senderId'] != _userId) {
          count++;
        }
      }

      return count;
    } catch (e) {
      throw Exception(
        'Failed to get unread message count: $e',
      );
    }
  }

  // ============================================================
  // PRIVATE ACCESS CHECK
  // ============================================================

  /// Make sure the current user belongs to the chat.
  Future<void> _verifyChatAccess(
    String chatId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _chat(chatId).get();

    if (!snapshot.exists) {
      throw Exception('Chat does not exist.');
    }

    final data = snapshot.data() ?? {};

    final List<dynamic> participants =
        data['participants'] ?? [];

    if (!participants.contains(_userId)) {
      throw Exception(
        'You do not have access to this chat.',
      );
    }
  }
}