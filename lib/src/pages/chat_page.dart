import 'dart:async';
import 'dart:ui' as ui;

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

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _isSending = false;
  bool _isSendingAttachment = false;
  bool _isMarkingRead = false;

  /// 0 = Chat
  /// 1 = Communities
  /// 2 = Unread
  /// 3 = Favorite
  /// 4 = Folders
  int _selectedFilter = 0;

  String? _activeFolderId;
  String? _activeFolderName;
  Set<String> _activeFolderChatIds = {};

  // Keeps the active folder's chat list live instead of a one-off
  // snapshot, so adding/removing chats from a folder updates the
  // Folders tab immediately.
  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _folderSub;

  Map<String, dynamic>? _replyTo;

  User? get _currentUser =>
      _auth.currentUser;

  String? get _userId =>
      _currentUser?.uid;

  bool get _isConversation =>
      widget.chatId != null &&
      widget.chatId!.trim().isNotEmpty;

  CollectionReference<Map<String, dynamic>>
      get _messagesRef {
    if (!_isConversation) {
      throw StateError(
        'No chat ID provided.',
      );
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
      _restoreChatForMe();
      _markChatAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _folderSub?.cancel();
    super.dispose();
  }

  // ============================================================
  // RESTORE HIDDEN CHAT
  // ============================================================

  /// Opening a merchant chat makes the conversation visible again.
  /// This is what allows a deleted/hidden customer ↔ merchant chat
  /// to be reopened from Product Details using the same chat ID.
  Future<void> _restoreChatForMe() async {
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
          'hiddenFor':
              FieldValue.arrayRemove([uid]),

          // Legacy compatibility for older chats.
          'deletedFor':
              FieldValue.arrayRemove([uid]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Restore chat error: $e',
      );
    }
  }

  // ============================================================
  // MARK CHAT AS READ
  // ============================================================

  Future<void> _markChatAsRead() async {
    final uid = _userId;

    if (uid == null ||
        !_isConversation ||
        _isMarkingRead) {
      return;
    }

    _isMarkingRead = true;

    try {
      final chatRef = _firestore
          .collection('chats')
          .doc(widget.chatId);

      final chatSnapshot =
          await chatRef.get();

      final chatData =
          chatSnapshot.data() ??
              <String, dynamic>{};

      final participants = <String>[];

      final rawParticipants =
          chatData['participants'];

      if (rawParticipants is List) {
        for (final participant
            in rawParticipants) {
          final id =
              participant?.toString().trim();

          if (id != null && id.isNotEmpty) {
            participants.add(id);
          }
        }
      }

      if (!participants.contains(uid)) {
        participants.add(uid);
      }

      final unreadCounts =
          <String, dynamic>{
        ...?_asMap(
          chatData['unreadCounts'],
        ),
      };

      unreadCounts[uid] = 0;

      var totalUnread = 0;

      for (final participant
          in participants) {
        final count =
            unreadCounts[participant];

        if (count is num && count > 0) {
          totalUnread += count.toInt();
        }
      }

      await chatRef.set(
        {
          'unreadCounts': unreadCounts,
          'unreadFor':
              FieldValue.arrayRemove([uid]),
          'unread': totalUnread > 0,
          'unreadCount': totalUnread,
        },
        SetOptions(merge: true),
      );

      // Only fetch messages that are still unread,
      // instead of the entire message history.
      final messageSnapshot =
          await _messagesRef
              .where(
                'read',
                isEqualTo: false,
              )
              .get();

      final batch =
          _firestore.batch();

      var changed = false;

      for (final doc
          in messageSnapshot.docs) {
        final data = doc.data();

        final senderId =
            data['senderId']?.toString();

        if (senderId == null ||
            senderId == uid) {
          continue;
        }

        final alreadyRead =
            data['read'] == true;

        final alreadyDelivered =
            data['delivered'] == true;

        if (alreadyRead &&
            alreadyDelivered) {
          continue;
        }

        batch.update(
          doc.reference,
          {
            'delivered': true,
            'read': true,
            'deliveredAt':
                data['deliveredAt'] ??
                    FieldValue
                        .serverTimestamp(),
            'readAt':
                FieldValue.serverTimestamp(),
          },
        );

        changed = true;
      }

      if (changed) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint(
        'Mark chat read error: $e',
      );
    } finally {
      _isMarkingRead = false;
    }
  }

  // ============================================================
  // SEND TEXT
  // ============================================================

  Future<void> _sendMessage() async {
    final text =
        _messageController.text.trim();

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
        'delivered': false,
        'read': false,
        'deleted': false,
        'reactions':
            <String, dynamic>{},
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
          'imageUrl':
              _replyTo!['imageUrl'],
          'stickerUrl':
              _replyTo!['stickerUrl'],
        };
      }

      await messageRef.set(
        messageData,
      );

      await _updateChatPreview(
        chatRef: chatRef,
        preview: text,
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
          DateTime.now()
              .millisecondsSinceEpoch;

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
          await uploadTask.ref
              .getDownloadURL();

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
        'delivered': false,
        'read': false,
        'deleted': false,
        'reactions':
            <String, dynamic>{},
      });

      await _updateChatPreview(
        chatRef: chatRef,
        preview: '📷 Image',
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
  // SEND GALLERY IMAGE AS STICKER
  // ============================================================

  /// Picks a picture from the gallery and sends it as a
  /// small sticker-style image instead of a normal image.
  Future<void> _sendGallerySticker() async {
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
        imageQuality: 75,
        maxWidth: 900,
        maxHeight: 900,
      );

      if (picked == null) {
        return;
      }

      // Close the sticker picker after the user
      // successfully chooses a picture.
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isSendingAttachment = true;
      });

      final fileBytes =
          await picked.readAsBytes();

      final timestamp =
          DateTime.now()
              .millisecondsSinceEpoch;

      final storageRef = _storage
          .ref()
          .child('chat_stickers')
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

      final stickerUrl =
          await uploadTask.ref
              .getDownloadURL();

      final chatRef = _firestore
          .collection('chats')
          .doc(widget.chatId);

      final messageRef =
          chatRef.collection('messages').doc();

      await messageRef.set({
        'senderId': _userId,
        'text': '',
        'type': 'sticker',
        'stickerUrl': stickerUrl,
        'createdAt':
            FieldValue.serverTimestamp(),
        'delivered': false,
        'read': false,
        'deleted': false,
        'reactions':
            <String, dynamic>{},
      });

      await _updateChatPreview(
        chatRef: chatRef,
        preview: '🎨 Sticker',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Send gallery sticker error: $e',
      );
      debugPrint(
        'Stack trace: $stackTrace',
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
  // SEND EMOJI STICKER
  // ============================================================

  /// The picker lets the user choose sticker designs using emoji
  /// as the visual source, but the actual Firestore message is an
  /// uploaded PNG image, not an emoji text message.
  Future<void> _sendSticker(
    String emoji,
  ) async {
    if (_userId == null ||
        !_isConversation ||
        _isSending ||
        _isSendingAttachment) {
      return;
    }

    Navigator.of(context).pop();

    setState(() {
      _isSendingAttachment = true;
    });

    try {
      final stickerBytes =
          await _emojiToPng(emoji);

      final timestamp =
          DateTime.now()
              .millisecondsSinceEpoch;

      final storageRef = _storage
          .ref()
          .child('chat_stickers')
          .child(widget.chatId!)
          .child(
            '${_userId}_$timestamp.png',
          );

      final uploadTask =
          await storageRef.putData(
        stickerBytes,
        SettableMetadata(
          contentType: 'image/png',
        ),
      );

      final stickerUrl =
          await uploadTask.ref
              .getDownloadURL();

      final chatRef = _firestore
          .collection('chats')
          .doc(widget.chatId);

      final messageRef =
          chatRef.collection('messages').doc();

      await messageRef.set({
        'senderId': _userId,
        'text': '',
        'type': 'sticker',
        'stickerUrl': stickerUrl,
        'createdAt':
            FieldValue.serverTimestamp(),
        'delivered': false,
        'read': false,
        'deleted': false,
        'reactions':
            <String, dynamic>{},
      });

      await _updateChatPreview(
        chatRef: chatRef,
        preview: '🎨 Sticker',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Send sticker error: $e',
      );
      debugPrint(
        'Stack trace: $stackTrace',
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
  // TURN EMOJI INTO REAL PNG
  // ============================================================

  Future<Uint8List> _emojiToPng(
    String emoji,
  ) async {
    const size = 180.0;

    final recorder =
        ui.PictureRecorder();

    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(
        0,
        0,
        size,
        size,
      ),
    );

    final textPainter =
        TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(
          fontSize: 105,
          height: 1,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );

    textPainter.paint(
      canvas,
      offset,
    );

    final picture =
        recorder.endRecording();

    final image =
        await picture.toImage(
      size.toInt(),
      size.toInt(),
    );

    final byteData =
        await image.toByteData(
      format:
          ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw StateError(
        'Could not create sticker image.',
      );
    }

    return byteData.buffer
        .asUint8List();
  }

  // ============================================================
  // UPDATE CHAT PREVIEW + UNREAD
  // ============================================================

  Future<void> _updateChatPreview({
    required DocumentReference<
            Map<String, dynamic>>
        chatRef,
    required String preview,
  }) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    final chatSnapshot =
        await chatRef.get();

    final chatData =
        chatSnapshot.data() ??
            <String, dynamic>{};

    final participants =
        <String>{};

    final rawParticipants =
        chatData['participants'];

    if (rawParticipants is List) {
      for (final participant
          in rawParticipants) {
        final id =
            participant?.toString().trim();

        if (id != null &&
            id.isNotEmpty) {
          participants.add(id);
        }
      }
    }

    participants.add(uid);

    final unreadCounts =
        <String, dynamic>{
      ...?_asMap(
        chatData['unreadCounts'],
      ),
    };

    final unreadFor =
        <String>{};

    final existingUnreadFor =
        chatData['unreadFor'];

    if (existingUnreadFor is List) {
      unreadFor.addAll(
        existingUnreadFor.map(
          (e) => e.toString(),
        ),
      );
    }

    for (final participant
        in participants) {
      if (participant == uid) {
        unreadCounts[participant] ??= 0;
        continue;
      }

      final oldCount =
          unreadCounts[participant];

      final currentCount =
          oldCount is num
              ? oldCount.toInt()
              : 0;

      unreadCounts[participant] =
          currentCount + 1;

      unreadFor.add(participant);
    }

    var totalUnread = 0;

    for (final value
        in unreadCounts.values) {
      if (value is num &&
          value > 0) {
        totalUnread += value.toInt();
      }
    }

    await chatRef.set(
      {
        'participants':
            participants.toList(),
        'lastMessage': preview,
        'lastMessageSenderId': uid,
        'updatedAt':
            FieldValue.serverTimestamp(),
        'unreadCounts': unreadCounts,
        'unreadFor':
            unreadFor.toList(),
        'unread':
            totalUnread > 0,
        'unreadCount':
            totalUnread,
        'hiddenFor':
            FieldValue.arrayRemove([uid]),
        'deletedFor':
            FieldValue.arrayRemove([uid]),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // CHAT STREAM
  // ============================================================

  Stream<QuerySnapshot<
      Map<String, dynamic>>> _chatStream() {
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

  List<QueryDocumentSnapshot<
      Map<String, dynamic>>> _sortChats(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
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

    return DateTime
        .fromMillisecondsSinceEpoch(0);
  }

  // ============================================================
  // FILTER CHAT LIST
  // ============================================================

  List<QueryDocumentSnapshot<
      Map<String, dynamic>>> _filterChats(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        chats,
  ) {
    final uid = _userId;

    if (uid == null) {
      return [];
    }

    final visibleChats =
        chats.where((doc) {
      final data = doc.data();

      final hiddenFor =
          data['hiddenFor'];

      final isHiddenForMe =
          hiddenFor is List &&
              hiddenFor.contains(uid);

      final legacyDeletedFor =
          data['deletedFor'];

      final isLegacyHidden =
          legacyDeletedFor is List &&
              legacyDeletedFor.contains(uid);

      if (isHiddenForMe ||
          isLegacyHidden) {
        return false;
      }

      return true;
    }).toList();

    if (_selectedFilter == 0) {
      return visibleChats.where((doc) {
        final data = doc.data();

        final type =
            data['type']
                ?.toString()
                .toLowerCase();

        return type != 'community' &&
            data['isCommunity'] != true;
      }).toList();
    }

    if (_selectedFilter == 1) {
      return visibleChats.where((doc) {
        final data = doc.data();

        final type =
            data['type']
                ?.toString()
                .toLowerCase();

        return type == 'community' ||
            data['isCommunity'] == true;
      }).toList();
    }

    if (_selectedFilter == 2) {
      return visibleChats.where((doc) {
        return _getUnreadCount(
              doc.data(),
            ) >
            0;
      }).toList();
    }

    if (_selectedFilter == 3) {
      return visibleChats.where((doc) {
        final data = doc.data();

        final favoriteFor =
            data['favoriteFor'];

        return favoriteFor is List &&
            favoriteFor.contains(uid);
      }).toList();
    }

    if (_selectedFilter == 4) {
      if (_activeFolderId == null) {
        return [];
      }

      return visibleChats.where((doc) {
        return _activeFolderChatIds
            .contains(doc.id);
      }).toList();
    }

    return visibleChats;
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void> _setFavorite(
    String chatId,
    bool value,
  ) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    await _firestore
        .collection('chats')
        .doc(chatId)
        .set(
      {
        'favoriteFor': value
            ? FieldValue.arrayUnion(
                [uid],
              )
            : FieldValue.arrayRemove(
                [uid],
              ),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // FOLDERS
  // ============================================================

  Future<void> _createChatFolder() async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    final controller =
        TextEditingController();

    final name =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              pikkXWhite,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Create folder',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration:
                InputDecoration(
              hintText:
                  'Sellers, Friends, Orders...',
              filled: true,
              fillColor:
                  pikkXBackground,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    pikkXBlack,
                foregroundColor:
                    pikkXWhite,
              ),
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(
                    context,
                    value,
                  );
                }
              },
              child:
                  const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null ||
        name.trim().isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatFolders')
          .add({
        'name': name.trim(),
        'chatIds': <String>[],
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage(
          'Folder created.',
        );
      }
    } catch (e) {
      debugPrint(
        'Create folder error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not create folder.',
        );
      }
    }
  }

  // Subscribes to a single chat folder document so the Folders tab
  // stays live.
  void _subscribeToFolder(
    String folderId,
    String fallbackName,
  ) {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    _folderSub?.cancel();

    _folderSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('chatFolders')
        .doc(folderId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) {
        return;
      }

      final data =
          snapshot.data() ??
              <String, dynamic>{};

      final rawIds =
          data['chatIds'];

      final ids = <String>{};

      if (rawIds is List) {
        ids.addAll(
          rawIds.map(
            (e) => e.toString(),
          ),
        );
      }

      setState(() {
        _activeFolderName =
            data['name']
                    ?.toString() ??
                fallbackName;

        _activeFolderChatIds =
            ids;
      });
    });
  }

  Future<void> _showFolderMenu() async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    setState(() {
      _selectedFilter = 4;
    });

    if (!mounted) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child:
              DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.35,
            maxChildSize: 0.88,
            builder: (_, controller) {
              return Container(
                decoration:
                    const BoxDecoration(
                  color: pikkXWhite,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(
                      28,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    _sheetHandle(),
                    const SizedBox(
                      height: 14,
                    ),
                    const Text(
                      'Chat folders',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Expanded(
                      child:
                          StreamBuilder<
                              QuerySnapshot<
                                  Map<String,
                                      dynamic>>>(
                        stream: _firestore
                            .collection(
                              'users',
                            )
                            .doc(uid)
                            .collection(
                              'chatFolders',
                            )
                            .orderBy(
                              'createdAt',
                              descending:
                                  false,
                            )
                            .snapshots(),
                        builder:
                            (
                          context,
                          snapshot,
                        ) {
                          if (snapshot
                                      .connectionState ==
                                  ConnectionState
                                      .waiting &&
                              !snapshot
                                  .hasData) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(
                                color:
                                    pikkXBlack,
                              ),
                            );
                          }

                          final docs =
                              snapshot.data
                                      ?.docs ??
                                  [];

                          if (docs.isEmpty) {
                            return Center(
                              child:
                                  Padding(
                                padding:
                                    const EdgeInsets.all(
                                  25,
                                ),
                                child:
                                    Column(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            pikkXBlack.withOpacity(
                                          0.06,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(
                                          20,
                                        ),
                                      ),
                                      child:
                                          const Icon(
                                        Icons
                                            .folder_rounded,
                                        color:
                                            pikkXBlack,
                                        size:
                                            30,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    const Text(
                                      'No folders yet',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.w800,
                                        fontSize:
                                            17,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    const Text(
                                      'Create folders for Sellers, Friends, Orders and more.',
                                      textAlign:
                                          TextAlign.center,
                                      style:
                                          TextStyle(
                                        color:
                                            pikkXGrey,
                                        fontSize:
                                            12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            controller:
                                controller,
                            padding:
                                const EdgeInsets.fromLTRB(
                              14,
                              8,
                              14,
                              12,
                            ),
                            itemCount:
                                docs.length,
                            separatorBuilder:
                                (_, __) =>
                                    const SizedBox(
                              height: 6,
                            ),
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final folder =
                                  docs[index];

                              final data =
                                  folder.data();

                              final name =
                                  data['name']
                                          ?.toString() ??
                                      'Folder';

                              final rawIds =
                                  data['chatIds'];

                              final ids =
                                  <String>{};

                              if (rawIds
                                  is List) {
                                ids.addAll(
                                  rawIds.map(
                                    (e) =>
                                        e.toString(),
                                  ),
                                );
                              }

                              final selected =
                                  _activeFolderId ==
                                      folder.id;

                              return Material(
                                color:
                                    Colors.transparent,
                                child:
                                    InkWell(
                                  borderRadius:
                                      BorderRadius.circular(
                                    17,
                                  ),
                                  onTap: () {
                                    setState(
                                      () {
                                        _selectedFilter =
                                            4;
                                        _activeFolderId =
                                            folder.id;
                                        _activeFolderName =
                                            name;
                                        _activeFolderChatIds =
                                            ids;
                                      },
                                    );

                                    _subscribeToFolder(
                                      folder.id,
                                      name,
                                    );

                                    Navigator.pop(
                                      sheetContext,
                                    );
                                  },
                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          13,
                                      vertical:
                                          12,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: selected
                                          ? pikkXBlack
                                          : pikkXBackground,
                                      borderRadius:
                                          BorderRadius.circular(
                                        17,
                                      ),
                                    ),
                                    child:
                                        Row(
                                      children: [
                                        Container(
                                          width:
                                              40,
                                          height:
                                              40,
                                          decoration:
                                              BoxDecoration(
                                            color: selected
                                                ? Colors.white.withOpacity(
                                                    0.12,
                                                  )
                                                : pikkXWhite,
                                            borderRadius:
                                                BorderRadius.circular(
                                              13,
                                            ),
                                          ),
                                          child:
                                              Icon(
                                            Icons
                                                .folder_rounded,
                                            color: selected
                                                ? pikkXWhite
                                                : pikkXBlack,
                                            size:
                                                20,
                                          ),
                                        ),
                                        const SizedBox(
                                          width:
                                              11,
                                        ),
                                        Expanded(
                                          child:
                                              Text(
                                            name,
                                            maxLines:
                                                1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style:
                                                TextStyle(
                                              color: selected
                                                  ? pikkXWhite
                                                  : pikkXBlack,
                                              fontWeight:
                                                  FontWeight.w800,
                                              fontSize:
                                                  14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${ids.length}',
                                          style:
                                              TextStyle(
                                            color: selected
                                                ? Colors.white70
                                                : pikkXGrey,
                                            fontSize:
                                                11,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        14,
                        0,
                        14,
                        14,
                      ),
                      child: SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                pikkXBlack,
                            foregroundColor:
                                pikkXWhite,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical:
                                  13,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                            _createChatFolder();
                          },
                          icon:
                              const Icon(
                            Icons
                                .create_new_folder_rounded,
                            size: 19,
                          ),
                          label:
                              const Text(
                            'Create folder',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // ADD CHAT TO FOLDER
  // ============================================================

  Future<void> _showFolderPicker(
    String chatId,
  ) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    try {
      final folders =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('chatFolders')
              .get();

      if (!mounted) {
        return;
      }

      if (folders.docs.isEmpty) {
        _showMessage(
          'Create a folder first.',
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor:
            Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Container(
              constraints:
                  const BoxConstraints(
                maxHeight: 520,
              ),
              decoration:
                  const BoxDecoration(
                color: pikkXWhite,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(
                    28,
                  ),
                ),
              ),
              child:
                  ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  18,
                ),
                itemCount:
                    folders.docs.length + 1,
                separatorBuilder:
                    (_, __) =>
                        const SizedBox(
                  height: 6,
                ),
                itemBuilder:
                    (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding:
                          EdgeInsets.fromLTRB(
                        4,
                        5,
                        4,
                        5,
                      ),
                      child: Text(
                        'Add to folder',
                        style:
                            TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    );
                  }

                  final folder =
                      folders.docs[
                          index - 1];

                  final data =
                      folder.data();

                  final name =
                      data['name']
                              ?.toString() ??
                          'Folder';

                  final rawIds =
                      data['chatIds'];

                  final existing =
                      rawIds is List &&
                          rawIds.contains(
                            chatId,
                          );

                  return Material(
                    color:
                        Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius
                              .circular(
                        17,
                      ),
                      onTap: () async {
                        try {
                          await folder
                              .reference
                              .update({
                            'chatIds': existing
                                ? FieldValue
                                    .arrayRemove(
                                    [chatId],
                                  )
                                : FieldValue
                                    .arrayUnion(
                                    [chatId],
                                  ),
                            'updatedAt':
                                FieldValue
                                    .serverTimestamp(),
                          });

                          if (sheetContext
                              .mounted) {
                            Navigator.pop(
                              sheetContext,
                            );
                          }

                          if (mounted) {
                            _showMessage(
                              existing
                                  ? 'Removed from $name.'
                                  : 'Added to $name.',
                            );
                          }
                        } catch (e) {
                          debugPrint(
                            'Folder assignment error: $e',
                          );

                          if (mounted) {
                            _showMessage(
                              'Could not update folder.',
                            );
                          }
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              pikkXBackground,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            17,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration:
                                  BoxDecoration(
                                color:
                                    pikkXWhite,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .folder_rounded,
                                color:
                                    pikkXBlack,
                                size: 20,
                              ),
                            ),
                            const SizedBox(
                              width: 11,
                            ),
                            Expanded(
                              child: Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize:
                                      14,
                                ),
                              ),
                            ),
                            Icon(
                              existing
                                  ? Icons
                                      .check_circle_rounded
                                  : Icons
                                      .add_circle_outline_rounded,
                              color:
                                  pikkXBlack,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Folder picker error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not load folders.',
        );
      }
    }
  }

  // ============================================================
  // DELETE CHAT FOR ME
  // ============================================================

  Future<void> _deleteChatForMe(
    String chatId,
  ) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(
        {
          'hiddenFor':
              FieldValue.arrayUnion([uid]),

          // Keep this temporarily for old data compatibility.
          'deletedFor':
              FieldValue.arrayUnion([uid]),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        _showMessage(
          'Chat hidden from your inbox.',
        );
      }
    } catch (e) {
      debugPrint(
        'Delete chat error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not hide chat.',
        );
      }
    }
  }

  // ============================================================
  // OTHER USER ID
  // ============================================================

  String? _otherUserId(
    Map<String, dynamic> data,
  ) {
    final uid = _userId;
    final participants =
        data['participants'];

    if (uid == null ||
        participants is! List) {
      return null;
    }

    for (final id in participants) {
      final value =
          id.toString();

      if (value != uid) {
        return value;
      }
    }

    return null;
  }

  // ============================================================
  // BLOCK
  // ============================================================

  Future<void> _blockUser(
    String chatId,
    Map<String, dynamic> data,
  ) async {
    final uid = _userId;
    final otherUid =
        _otherUserId(data);

    if (uid == null ||
        otherUid == null) {
      if (mounted) {
        _showMessage(
          'Could not identify this user.',
        );
      }

      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('blockedUsers')
          .doc(otherUid)
          .set({
        'userId': otherUid,
        'chatId': chatId,
        'blockedAt':
            FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage(
          'User blocked.',
        );
      }
    } catch (e) {
      debugPrint(
        'Block user error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not block user.',
        );
      }
    }
  }

  // ============================================================
  // REPORT
  // ============================================================

  Future<void> _reportChat(
    String chatId,
    Map<String, dynamic> data,
  ) async {
    final uid = _userId;
    final otherUid =
        _otherUserId(data);

    if (uid == null ||
        otherUid == null) {
      if (mounted) {
        _showMessage(
          'Could not identify this user.',
        );
      }

      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('reports')
          .add({
        'chatId': chatId,
        'reportedUserId': otherUid,
        'reportedAt':
            FieldValue.serverTimestamp(),
        'type': 'chat',
      });

      if (mounted) {
        _showMessage(
          'Report submitted.',
        );
      }
    } catch (e) {
      debugPrint(
        'Report chat error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not submit report.',
        );
      }
    }
  }

  // ============================================================
  // CHAT TILE
  // ============================================================

  Widget _buildChatTile(
    String chatId,
    Map<String, dynamic> data,
  ) {
    final name =
        data['otherUserName']
                ?.toString() ??
            data['chatName']
                ?.toString() ??
            data['name']
                ?.toString();

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

    final favoriteFor =
        data['favoriteFor'];

    final isFavorite =
        favoriteFor is List &&
            _userId != null &&
            favoriteFor.contains(
              _userId,
            );

    return GestureDetector(
      onLongPress: () {
        _showChatActions(
          chatId,
          data,
        );
      },
      child: _glass(
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
                BorderRadius.circular(
              21,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              child: Row(
                children: [
                  _chatAvatar(
                    displayName,
                    isCommunity:
                        isCommunity,
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  color:
                                      pikkXBlack,
                                  fontSize:
                                      14,
                                  fontWeight:
                                      unreadCount >
                                              0
                                          ? FontWeight
                                              .w900
                                          : FontWeight
                                              .w800,
                                ),
                              ),
                            ),
                            if (isFavorite)
                              const Padding(
                                padding:
                                    EdgeInsets
                                        .only(
                                  left: 5,
                                ),
                                child:
                                    Icon(
                                  Icons
                                      .star_rounded,
                                  color:
                                      pikkXBlack,
                                  size:
                                      15,
                                ),
                              ),
                            if (unreadCount >
                                0)
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  left: 5,
                                ),
                                child:
                                    _unreadBadge(
                                  unreadCount,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          lastMessage
                                  .isEmpty
                              ? 'Start a conversation'
                              : lastMessage,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            color:
                                pikkXGrey,
                            fontSize:
                                11.5,
                            fontWeight:
                                unreadCount >
                                        0
                                    ? FontWeight
                                        .w600
                                    : FontWeight
                                        .w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXBlack,
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      color:
                          pikkXWhite,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHAT LONG PRESS ACTIONS
  // ============================================================

  void _showChatActions(
    String chatId,
    Map<String, dynamic> data,
  ) {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    final favoriteFor =
        data['favoriteFor'];

    final isFavorite =
        favoriteFor is List &&
            favoriteFor.contains(uid);

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child:
              DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.58,
            minChildSize: 0.35,
            maxChildSize: 0.88,
            builder: (_, controller) {
              return _glass(
                radius: 27,
                padding:
                    EdgeInsets.zero,
                child: ListView(
                  controller:
                      controller,
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    12,
                    10,
                    12,
                    18,
                  ),
                  children: [
                    _sheetHandle(),
                    const SizedBox(
                      height: 12,
                    ),
                    _actionTile(
                      icon: isFavorite
                          ? Icons
                              .star_rounded
                          : Icons
                              .star_border_rounded,
                      label: isFavorite
                          ? 'Remove from Favorite'
                          : 'Favorite',
                      onTap: () async {
                        Navigator.pop(
                          sheetContext,
                        );

                        await _setFavorite(
                          chatId,
                          !isFavorite,
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons
                          .folder_rounded,
                      label:
                          'Add to folder',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _showFolderPicker(
                          chatId,
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons
                          .notifications_off_rounded,
                      label: 'Mute',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _showMessage(
                          'Mute will be added next.',
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons
                          .push_pin_rounded,
                      label: 'Pin',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _showMessage(
                          'Pin will be added next.',
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons
                          .delete_outline_rounded,
                      label:
                          'Delete chat for me',
                      destructive:
                          true,
                      onTap: () async {
                        Navigator.pop(
                          sheetContext,
                        );

                        await _deleteChatForMe(
                          chatId,
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons
                          .block_rounded,
                      label: 'Block',
                      onTap: () async {
                        Navigator.pop(
                          sheetContext,
                        );

                        await _blockUser(
                          chatId,
                          data,
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons
                          .report_problem_outlined,
                      label: 'Report',
                      onTap: () async {
                        Navigator.pop(
                          sheetContext,
                        );

                        await _reportChat(
                          chatId,
                          data,
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons
                          .close_rounded,
                      label: 'Cancel',
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration:
            BoxDecoration(
          color:
              pikkXGrey.withOpacity(
            0.4,
          ),
          borderRadius:
              BorderRadius.circular(
            5,
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
    final uid = _userId;

    if (uid != null) {
      final unreadCounts =
          _asMap(
        data['unreadCounts'],
      );

      final personalCount =
          unreadCounts?[uid];

      if (personalCount is num &&
          personalCount > 0) {
        return personalCount.toInt();
      }
    }

    final legacyCount =
        data['unreadCount'];

    if (legacyCount is num &&
        legacyCount > 0) {
      return legacyCount.toInt();
    }

    if (data['unread'] == true) {
      return 1;
    }

    final unreadFor =
        data['unreadFor'];

    if (unreadFor is List &&
        uid != null &&
        unreadFor.contains(uid)) {
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
      decoration:
          BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      alignment:
          Alignment.center,
      child: Text(
        count > 99
            ? '99+'
            : count.toString(),
        style:
            const TextStyle(
          color: pikkXWhite,
          fontSize: 9,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (!_isConversation) {
      return _buildInbox();
    }

    return _buildConversation();
  }

  // ============================================================
  // INBOX
  // ============================================================

  Widget _buildInbox() {
    return Scaffold(
      backgroundColor:
          pikkXBackground,
      body: _userId == null
          ? _buildSignInState()
          : Stack(
              children: [
                Column(
                  children: [
                    _buildFilterBox(),
                    Expanded(
                      child:
                          StreamBuilder<
                              QuerySnapshot<
                                  Map<String,
                                      dynamic>>>(
                        stream:
                            _chatStream(),
                        builder: (
                          context,
                          snapshot,
                        ) {
                          if (snapshot
                                  .connectionState ==
                              ConnectionState
                                  .waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(
                                color:
                                    pikkXBlack,
                              ),
                            );
                          }

                          if (snapshot
                              .hasError) {
                            debugPrint(
                              'Chat stream error: '
                              '${snapshot.error}',
                            );

                            return _buildErrorState();
                          }

                          final allChats =
                              snapshot.data
                                      ?.docs ??
                                  [];

                          final filteredChats =
                              _filterChats(
                            allChats,
                          );

                          final chats =
                              _sortChats(
                            filteredChats,
                          );

                          if (chats.isEmpty) {
                            if (_selectedFilter ==
                                0) {
                              return _buildFilterEmptyState(
                                'No chats yet',
                                'Your conversations with sellers and support will appear here.',
                                Icons
                                    .chat_bubble_outline_rounded,
                              );
                            }

                            if (_selectedFilter ==
                                1) {
                              return _buildFilterEmptyState(
                                'No community chats',
                                'Community conversations will appear here.',
                                Icons
                                    .groups_rounded,
                              );
                            }

                            if (_selectedFilter ==
                                2) {
                              return _buildFilterEmptyState(
                                'No unread chats',
                                'You are all caught up.',
                                Icons
                                    .mark_chat_read_rounded,
                              );
                            }

                            if (_selectedFilter ==
                                3) {
                              return _buildFilterEmptyState(
                                'No favorite chats',
                                'Favorite conversations will appear here.',
                                Icons
                                    .star_border_rounded,
                              );
                            }

                            if (_selectedFilter ==
                                    4 &&
                                _activeFolderId ==
                                    null) {
                              return _buildFilterEmptyState(
                                'Choose a folder',
                                'Tap the Folders pill to view or create a chat folder.',
                                Icons
                                    .folder_rounded,
                              );
                            }

                            return _buildFilterEmptyState(
                              _activeFolderName ??
                                  'Empty folder',
                              'Chats added to this folder will appear here.',
                              Icons
                                  .folder_open_rounded,
                            );
                          }

                          return ListView
                              .builder(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              16,
                              4,
                              16,
                              105,
                            ),
                            itemCount:
                                chats.length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final doc =
                                  chats[index];

                              return Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  bottom:
                                      9,
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

                // Floating search button above bottom navigation.
                Positioned(
                  right: 18,
                  bottom: 18,
                  child:
                      GestureDetector(
                    onTap:
                        _showChatSearch,
                    child: _glass(
                      radius: 18,
                      padding:
                          const EdgeInsets
                              .all(
                        14,
                      ),
                      child:
                          const Icon(
                        Icons
                            .search_rounded,
                        color:
                            pikkXBlack,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // FILTER HEADER
  // ============================================================

  Widget _buildFilterBox() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        8,
      ),
      child: _glass(
        radius: 19,
        padding:
            const EdgeInsets.all(4),
        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          physics:
              const BouncingScrollPhysics(),
  Widget _buildFilterBox() {
    const filters = <String>[
      'Chat',
      'Communities',
      'Unread',
      'Favorite',
      'Folders',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        8,
      ),
      child: _glass(
        radius: 19,
        padding: const EdgeInsets.all(4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(
              filters.length,
              (index) {
                final selected = _selectedFilter == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      if (!mounted) return;

                      setState(() {
                        _selectedFilter = index;

                        if (index != 4) {
                          _activeFolderId = null;
                          _activeFolderName = null;
                          _activeFolderChatIds = <String>{};
                        }
                      });

                      if (index == 4) {
                        _showFolderPicker();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? pikkXBlack
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        filters[index],
                        style: TextStyle(
                          color: selected
                              ? pikkXWhite
                              : pikkXBlack,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _chatStream() {
    if (_userId == null) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('chats')
        .where(
          'participants',
          arrayContains: _userId,
        )
        .snapshots();
  }

  void _openChat(
    String chatId,
    String otherUserName,
  ) {
    if (chatId.trim().isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortChats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  ) {
    chats.sort((a, b) {
      final aData = a.data();
      final bData = b.data();

      final aTime = aData['updatedAt'];
      final bTime = bData['updatedAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      if (aTime is Timestamp) return -1;
      if (bTime is Timestamp) return 1;

      return 0;
    });

    return chats;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterChats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  ) {
    if (_userId == null) {
      return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }

    final visible = chats.where((doc) {
      final data = doc.data();

      final hiddenFor = _stringSet(data['hiddenFor']);
      final deletedFor = _stringSet(data['deletedFor']);

      if (hiddenFor.contains(_userId) ||
          deletedFor.contains(_userId)) {
        return false;
      }

      return true;
    }).toList();

    switch (_selectedFilter) {
      case 0:
        return visible;

      case 1:
        return visible.where((doc) {
          final data = doc.data();

          return data['type'] == 'community' ||
              data['chatType'] == 'community' ||
              data['isCommunity'] == true;
        }).toList();

      case 2:
        return visible.where((doc) {
          return _getUnreadCount(doc.data()) > 0;
        }).toList();

      case 3:
        return visible.where((doc) {
          final data = doc.data();
          final favoriteFor = _stringSet(
            data['favoriteFor'],
          );

          return favoriteFor.contains(_userId);
        }).toList();

      case 4:
        if (_activeFolderId == null) {
          return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        }

        return visible.where((doc) {
          return _activeFolderChatIds.contains(doc.id);
        }).toList();

      default:
        return visible;
    }
  }

  Set<String> _stringSet(dynamic value) {
    if (value is Iterable) {
      return value
          .whereType<String>()
          .toSet();
    }

    return <String>{};
  }

  Map<String, dynamic> _mapFromDynamic(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(
          key.toString(),
          value,
        ),
      );
    }

    return <String, dynamic>{};
  }

  Future<void> _setFavorite(
    String chatId,
    bool favorite,
  ) async {
    if (_userId == null || chatId.isEmpty) return;

    try {
      final ref = _firestore
          .collection('chats')
          .doc(chatId);

      if (favorite) {
        await ref.set(
          {
            'favoriteFor': FieldValue.arrayUnion(
              <String>[_userId!],
            ),
          },
          SetOptions(merge: true),
        );
      } else {
        await ref.set(
          {
            'favoriteFor': FieldValue.arrayRemove(
              <String>[_userId!],
            ),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('Favorite update error: $e');
    }
  }

  Future<void> _createFolder() async {
    if (_userId == null) return;

    final controller = TextEditingController();

    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: pikkXWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Create folder',
              style: TextStyle(
                color: pikkXBlack,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization:
                  TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Folder name',
                filled: true,
                fillColor: pikkXBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: pikkXGrey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final value =
                      controller.text.trim();

                  if (value.isEmpty) return;

                  Navigator.pop(
                    dialogContext,
                    value,
                  );
                },
                child: const Text(
                  'Create',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (name == null || name.trim().isEmpty) {
        return;
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatFolders')
          .add({
        'name': name.trim(),
        'chatIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage('Folder created.');
      }
    } catch (e) {
      debugPrint('Create folder error: $e');

      if (mounted) {
        _showMessage('Could not create folder.');
      }
    } finally {
      controller.dispose();
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _folderStream(
    String folderId,
  ) {
    if (_userId == null) {
      return const Stream<
          DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatFolders')
        .doc(folderId)
        .snapshots();
  }

  Future<void> _loadFolder(
    String folderId,
    String folderName,
  ) async {
    if (_userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatFolders')
          .doc(folderId)
          .get();

      final data = snapshot.data();

      if (!mounted) return;

      setState(() {
        _activeFolderId = folderId;
        _activeFolderName = folderName;
        _activeFolderChatIds = _stringSet(
          data?['chatIds'],
        );
        _selectedFilter = 4;
      });

      await _folderSub?.cancel();

      _folderSub = _folderStream(folderId).listen(
        (snapshot) {
          final data = snapshot.data();

          if (!mounted) return;

          setState(() {
            _activeFolderChatIds = _stringSet(
              data?['chatIds'],
            );
          });
        },
      );
    } catch (e) {
      debugPrint('Load folder error: $e');
    }
  }

  Future<void> _addChatToFolder(
    String folderId,
    String chatId,
  ) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatFolders')
          .doc(folderId)
          .set(
        {
          'chatIds': FieldValue.arrayUnion(
            <String>[chatId],
          ),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        _showMessage('Added to folder.');
      }
    } catch (e) {
      debugPrint('Add chat to folder error: $e');

      if (mounted) {
        _showMessage(
          'Could not add chat to folder.',
        );
      }
    }
  }

  Future<void> _removeChatFromFolder(
    String folderId,
    String chatId,
  ) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatFolders')
          .doc(folderId)
          .set(
        {
          'chatIds': FieldValue.arrayRemove(
            <String>[chatId],
          ),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Remove chat from folder error: $e',
      );
    }
  }

  Future<void> _showFolderPicker({
    String? chatId,
  }) async {
    if (_userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatFolders')
          .orderBy('createdAt')
          .get();

      final folders = snapshot.docs;

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: pikkXWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: pikkXLightGrey,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Folders',
                    style: TextStyle(
                      color: pikkXBlack,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (folders.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.folder_open_rounded,
                            size: 42,
                            color: pikkXGrey,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No folders yet',
                            style: TextStyle(
                              color: pikkXBlack,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Create a folder to organize your chats.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: pikkXGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...folders.map((folder) {
                      final data =
                          folder.data();
                      final name =
                          (data['name'] ?? 'Folder')
                              .toString();

                      final chatIds = _stringSet(
                        data['chatIds'],
                      );

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: pikkXBackground,
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: const Icon(
                            Icons.folder_rounded,
                            color: pikkXBlack,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: pikkXBlack,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${chatIds.length} chat${chatIds.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: pikkXGrey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: pikkXGrey,
                        ),
                        onTap: () async {
                          if (chatId != null) {
                            await _addChatToFolder(
                              folder.id,
                              chatId,
                            );

                            if (sheetContext.mounted) {
                              Navigator.pop(
                                sheetContext,
                              );
                            }
                          } else {
                            if (sheetContext.mounted) {
                              Navigator.pop(
                                sheetContext,
                              );
                            }

                            await _loadFolder(
                              folder.id,
                              name,
                            );
                          }
                        },
                      );
                    }),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _createFolder();
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                      ),
                      label: const Text(
                        'Create new folder',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pikkXBlack,
                        side: const BorderSide(
                          color: pikkXLightGrey,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Folder picker error: $e');

      if (mounted) {
        _showMessage(
          'Could not load folders.',
        );
      }
    }
  }

  Future<void> _deleteChatForMe(
    String chatId,
  ) async {
    if (_userId == null || chatId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(
        {
          'hiddenFor': FieldValue.arrayUnion(
            <String>[_userId!],
          ),
          'deletedFor': FieldValue.arrayUnion(
            <String>[_userId!],
          ),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        _showMessage('Chat removed for you.');
      }
    } catch (e) {
      debugPrint('Delete chat error: $e');

      if (mounted) {
        _showMessage(
          'Could not remove chat.',
        );
      }
    }
  }

  String? _otherUserId(
    Map<String, dynamic> data,
  ) {
    final participants = _stringSet(
      data['participants'],
    );

    if (_userId == null) return null;

    for (final id in participants) {
      if (id != _userId) {
        return id;
      }
    }

    return null;
  }

  Future<void> _blockUser(
    String chatId,
    String? otherUserId,
  ) async {
    if (_userId == null ||
        otherUserId == null ||
        otherUserId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('blockedUsers')
          .doc(otherUserId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage('User blocked.');
      }
    } catch (e) {
      debugPrint('Block user error: $e');

      if (mounted) {
        _showMessage('Could not block user.');
      }
    }
  }

  Future<void> _reportChat(
    String chatId,
    String? otherUserId,
  ) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('chatReports')
          .add({
        'chatId': chatId,
        'reporterId': _userId,
        'reportedUserId': otherUserId,
        'createdAt':
            FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        _showMessage(
          'Report submitted.',
        );
      }
    } catch (e) {
      debugPrint('Report chat error: $e');

      if (mounted) {
        _showMessage(
          'Could not submit report.',
        );
      }
    }
  }

  int _getUnreadCount(
    Map<String, dynamic> data,
  ) {
    if (_userId == null) return 0;

    final unreadCounts = _mapFromDynamic(
      data['unreadCounts'],
    );

    final directValue =
        unreadCounts[_userId!];

    if (directValue is num) {
      return directValue.toInt();
    }

    final unreadFor = _stringSet(
      data['unreadFor'],
    );

    if (unreadFor.contains(_userId)) {
      return 1;
    }

    final unread = _stringSet(
      data['unread'],
    );

    if (unread.contains(_userId)) {
      return 1;
    }

    final legacy =
        data['unreadCount'];

    if (legacy is num) {
      return legacy.toInt();
    }

    return 0;
  }

  Widget _unreadBadge(
    int count,
  ) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final label = count > 99
        ? '99+'
        : count.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: pikkXWhite,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildChatTile(
    QueryDocumentSnapshot<
        Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final name = (
      data['otherUserName'] ??
      data['name'] ??
      data['title'] ??
      'PikkX User'
    ).toString();

    final preview = (
      data['lastMessage'] ??
      ''
    ).toString();

    final unreadCount =
        _getUnreadCount(data);

    final favoriteFor = _stringSet(
      data['favoriteFor'],
    );

    final isFavorite =
        _userId != null &&
        favoriteFor.contains(_userId);

    final otherUserId =
        _otherUserId(data);

    return GestureDetector(
      onTap: () {
        _openChat(doc.id, name);
      },
      onLongPress: () {
        _showChatActions(
          doc.id,
          name,
          isFavorite,
          otherUserId,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: pikkXWhite,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: pikkXLightGrey,
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _chatAvatar(
              name,
              data,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: pikkXBlack,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isFavorite)
                        const Padding(
                          padding:
                              EdgeInsets.only(
                            left: 5,
                          ),
                          child: Icon(
                            Icons
                                .favorite_rounded,
                            size: 15,
                            color: pikkXBlack,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview.isEmpty
                        ? 'Start chatting'
                        : preview,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? pikkXBlack
                          : pikkXGrey,
                      fontSize: 12.5,
                      fontWeight:
                          unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            _unreadBadge(
              unreadCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatAvatar(
    String name,
    Map<String, dynamic> data,
  ) {
    final imageUrl = (
      data['otherUserPhotoUrl'] ??
      data['photoUrl'] ??
      data['imageUrl'] ??
      ''
    ).toString().trim();

    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(17),
        child: Image.network(
          imageUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _avatarFallback(name);
          },
        ),
      );
    }

    return _avatarFallback(name);
  }

  Widget _avatarFallback(
    String name,
  ) {
    final firstLetter = name.trim().isEmpty
        ? 'P'
        : name.trim()[0].toUpperCase();

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: pikkXWhite,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _showChatActions(
    String chatId,
    String name,
    bool isFavorite,
    String? otherUserId,
  ) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: pikkXWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: pikkXLightGrey,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                _actionTile(
                  icon: isFavorite
                      ? Icons
                          .favorite_border_rounded
                      : Icons
                          .favorite_rounded,
                  title: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _setFavorite(
                      chatId,
                      !isFavorite,
                    );
                  },
                ),

                _actionTile(
                  icon:
                      Icons.folder_rounded,
                  title: 'Add to folder',
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _showFolderPicker(
                      chatId: chatId,
                    );
                  },
                ),

                _actionTile(
                  icon:
                      Icons.notifications_none_rounded,
                  title: 'Mute',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage(
                      'Mute is coming soon.',
                    );
                  },
                ),

                _actionTile(
                  icon: Icons.push_pin_outlined,
                  title: 'Pin',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage(
                      'Pin is coming soon.',
                    );
                  },
                ),

                _actionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete chat for me',
                  destructive: true,
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _deleteChatForMe(
                      chatId,
                    );
                  },
                ),

                _actionTile(
                  icon: Icons.block_rounded,
                  title: 'Block',
                  destructive: true,
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _blockUser(
                      chatId,
                      otherUserId,
                    );
                  },
                ),

                _actionTile(
                  icon:
                      Icons.flag_outlined,
                  title: 'Report',
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _reportChat(
                      chatId,
                      otherUserId,
                    );
                  },
                ),

                _actionTile(
                  icon: Icons.close_rounded,
                  title: 'Cancel',
                  onTap: () {
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: destructive
              ? pikkXBlack
                  .withValues(alpha: 0.06)
              : pikkXBackground,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: destructive
              ? pikkXRed
              : pikkXBlack,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: destructive
              ? pikkXRed
              : pikkXBlack,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _showChatSearch() async {
    if (!mounted) return;

    _searchController.clear();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(
                sheetContext,
              ).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: pikkXWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: pikkXLightGrey,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller:
                        _searchController,
                    autofocus: true,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration:
                        InputDecoration(
                      hintText:
                          'Search chats or people',
                      prefixIcon:
                          const Icon(
                        Icons.search_rounded,
                        color: pikkXBlack,
                      ),
                      suffixIcon:
                          _searchController
                                  .text
                                  .isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController
                                        .clear();
                                    setState(() {});
                                  },
                                  icon:
                                      const Icon(
                                    Icons
                                        .close_rounded,
                                  ),
                                ),
                      filled: true,
                      fillColor:
                          pikkXBackground,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          17,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      'Search your chats by name or conversation.',
                      style: TextStyle(
                        color: pikkXGrey,
                        fontSize: 12,
                      ),
                    ),
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
  // PART 3 — CONVERSATION UI / MESSAGES / IMAGES / STICKERS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _messageStream() {
    if (!_isConversation) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _messagesRef
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  String _messageId(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return doc.id;
  }

  bool _isMine(
    Map<String, dynamic> data,
  ) {
    return data['senderId'] == _userId;
  }

  DateTime? _messageDate(
    Map<String, dynamic> data,
  ) {
    final createdAt = data['createdAt'];

    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return null;
  }

  String _formatMessageTime(
    Map<String, dynamic> data,
  ) {
    final date = _messageDate(data);

    if (date == null) {
      return '';
    }

    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Future<void> _toggleReaction(
    String messageId,
    String emoji,
  ) async {
    if (_userId == null ||
        !_isConversation ||
        messageId.isEmpty ||
        emoji.isEmpty) {
      return;
    }

    try {
      final ref = _messagesRef.doc(messageId);

      final snapshot = await ref.get();
      final data = snapshot.data();

      if (data == null) return;

      final reactions = _mapFromDynamic(
        data['reactions'],
      );

      final users = _stringSet(
        reactions[emoji],
      );

      if (users.contains(_userId)) {
        await ref.update({
          'reactions.$emoji':
              FieldValue.arrayRemove(
            <String>[_userId!],
          ),
        });
      } else {
        await ref.set(
          {
            'reactions': {
              emoji: FieldValue.arrayUnion(
                <String>[_userId!],
              ),
            },
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint(
        'Reaction error: $e',
      );
    }
  }

  Future<void> _showReactionPicker(
    String messageId,
  ) async {
    if (!mounted) return;

    const reactions = <String>[
      '❤️',
      '😂',
      '😍',
      '😭',
      '😮',
      '😢',
      '😡',
      '👍',
      '👎',
      '👏',
      '🔥',
      '🎉',
      '🥰',
      '🤣',
      '🙏',
      '💯',
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: pikkXWhite,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: pikkXLightGrey,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'React to message',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment:
                      WrapAlignment.center,
                  spacing: 5,
                  runSpacing: 5,
                  children: reactions.map(
                    (emoji) {
                      return InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        onTap: () async {
                          Navigator.pop(
                            sheetContext,
                          );

                          await _toggleReaction(
                            messageId,
                            emoji,
                          );
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            7,
                          ),
                          child: Text(
                            emoji,
                            style:
                                const TextStyle(
                              fontSize: 29,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMessageActions(
    QueryDocumentSnapshot<
        Map<String, dynamic>> doc,
  ) async {
    if (!mounted) return;

    final data = doc.data();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: pikkXWhite,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: pikkXLightGrey,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 15),

                _actionTile(
                  icon:
                      Icons.add_reaction_outlined,
                  title: 'React',
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await _showReactionPicker(
                      doc.id,
                    );
                  },
                ),

                _actionTile(
                  icon: Icons.reply_rounded,
                  title: 'Reply',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    if (!mounted) return;

                    setState(() {
                      _replyTo = {
                        'messageId': doc.id,
                        'senderId':
                            data['senderId'],
                        'text':
                            data['text'] ?? '',
                        'type':
                            data['type'] ?? 'text',
                        'imageUrl':
                            data['imageUrl'],
                        'stickerUrl':
                            data['stickerUrl'],
                      };
                    });
                  },
                ),

                _actionTile(
                  icon: Icons.copy_rounded,
                  title: 'Copy',
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    final text =
                        (data['text'] ?? '')
                            .toString();

                    if (text.isNotEmpty) {
                      await Clipboard.setData(
                        ClipboardData(
                          text: text,
                        ),
                      );

                      if (mounted) {
                        _showMessage(
                          'Message copied.',
                        );
                      }
                    }
                  },
                ),

                if (_isMine(data))
                  _actionTile(
                    icon:
                        Icons.delete_outline_rounded,
                    title: 'Delete for me',
                    destructive: true,
                    onTap: () async {
                      Navigator.pop(
                        sheetContext,
                      );

                      try {
                        await _messagesRef
                            .doc(doc.id)
                            .set(
                          {
                            'deleted':
                                true,
                            'deletedFor':
                                FieldValue.arrayUnion(
                              <String>[
                                _userId!,
                              ],
                            ),
                            'text': '',
                          },
                          SetOptions(
                            merge: true,
                          ),
                        );
                      } catch (e) {
                        debugPrint(
                          'Delete message error: $e',
                        );
                      }
                    },
                  ),

                _actionTile(
                  icon: Icons.close_rounded,
                  title: 'Cancel',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    if (_replyTo == null) {
      return const SizedBox.shrink();
    }

    final reply = _replyTo!;

    final type =
        (reply['type'] ?? 'text').toString();

    String previewText =
        (reply['text'] ?? '').toString();

    if (type == 'image') {
      previewText = '📷 Image';
    } else if (type == 'sticker') {
      previewText = '🎨 Sticker';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        8,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: pikkXWhite,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: pikkXLightGrey,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: pikkXBlack,
              borderRadius:
                  BorderRadius.circular(10),
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
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  previewText.isEmpty
                      ? 'Message'
                      : previewText,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: pikkXGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyTo = null;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: pikkXGrey,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageReactions(
    Map<String, dynamic> data,
  ) {
    final reactions =
        _mapFromDynamic(
      data['reactions'],
    );

    final entries = reactions.entries
        .where((entry) {
      return _stringSet(
        entry.value,
      ).isNotEmpty;
    }).toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 4,
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 3,
        children: entries.map((entry) {
          final users = _stringSet(
            entry.value,
          );

          return GestureDetector(
            onTap: () {
              _toggleReaction(
                data['messageId']
                    ?.toString() ??
                    '',
                entry.key,
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: pikkXWhite,
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: pikkXLightGrey,
                ),
              ),
              child: Text(
                '${entry.key} ${users.length}',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageContent(
    QueryDocumentSnapshot<
        Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final type =
        (data['type'] ?? 'text').toString();

    if (data['deleted'] == true) {
      return const Text(
        'Message deleted',
        style: TextStyle(
          color: pikkXGrey,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      );
    }

    if (type == 'image') {
      final imageUrl =
          (data['imageUrl'] ?? '')
              .toString();

      if (imageUrl.isEmpty) {
        return const Text(
          'Image unavailable',
          style: TextStyle(
            color: pikkXGrey,
          ),
        );
      }

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder:
              (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value:
                      loadingProgress
                                  .expectedTotalBytes !=
                              null
                          ? loadingProgress
                                  .cumulativeBytesLoaded /
                              loadingProgress
                                  .expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              width: 220,
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pikkXBackground,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .broken_image_outlined,
                    color: pikkXGrey,
                    size: 32,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Could not load image',
                    style: TextStyle(
                      color: pikkXGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    if (type == 'sticker') {
      final stickerUrl =
          (data['stickerUrl'] ?? '')
              .toString();

      if (stickerUrl.isEmpty) {
        return const Text(
          'Sticker unavailable',
          style: TextStyle(
            color: pikkXGrey,
          ),
        );
      }

      // Gallery stickers intentionally stay SMALL.
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(18),
        child: Image.network(
          stickerUrl,
          width: 125,
          height: 125,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              width: 125,
              height: 125,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pikkXBackground,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                color: pikkXGrey,
              ),
            );
          },
        ),
      );
    }

    final text =
        (data['text'] ?? '').toString();

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      text,
      style: const TextStyle(
        color: pikkXBlack,
        fontSize: 14.5,
        height: 1.35,
      ),
    );
  }

  Widget _buildMessageBubble(
    QueryDocumentSnapshot<
        Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final mine = _isMine(data);
    final type =
        (data['type'] ?? 'text').toString();

    final time =
        _formatMessageTime(data);

    final reactions =
        _mapFromDynamic(
      data['reactions'],
    );

    final replyTo =
        _mapFromDynamic(
      data['replyTo'],
    );

    final bubbleColor = mine
        ? pikkXBlack
        : pikkXWhite;

    final textColor = mine
        ? pikkXWhite
        : pikkXBlack;

    final isVisualMessage =
        type == 'image' ||
        type == 'sticker';

    return GestureDetector(
      onLongPress: () {
        _showMessageActions(doc);
      },
      onDoubleTap: () {
        _toggleReaction(
          doc.id,
          '❤️',
        );
      },
      child: Align(
        alignment: mine
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth: 285,
          ),
          margin: EdgeInsets.only(
            left: mine ? 50 : 12,
            right: mine ? 12 : 50,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (replyTo.isNotEmpty)
                Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 5,
                  ),
                  padding:
                      const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mine
                        ? Colors.black12
                        : pikkXBackground,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Text(
                    (replyTo['text'] ??
                            'Replied message')
                        .toString()
                        .isEmpty
                        ? 'Replied message'
                        : (replyTo['text'] ??
                                'Replied message')
                            .toString(),
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mine
                          ? pikkXWhite
                              .withValues(
                            alpha: 0.75,
                          )
                          : pikkXGrey,
                      fontSize: 11,
                    ),
                  ),
                ),

              Container(
                padding: isVisualMessage
                    ? const EdgeInsets.all(5)
                    : const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        const Radius.circular(
                      19,
                    ),
                    topRight:
                        const Radius.circular(
                      19,
                    ),
                    bottomLeft:
                        Radius.circular(
                      mine ? 19 : 5,
                    ),
                    bottomRight:
                        Radius.circular(
                      mine ? 5 : 19,
                    ),
                  ),
                  border: mine
                      ? null
                      : Border.all(
                          color:
                              pikkXLightGrey,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.035,
                      ),
                      blurRadius: 8,
                      offset:
                          const Offset(0, 3),
                    ),
                  ],
                ),
                child: type == 'image' ||
                        type == 'sticker'
                    ? _buildMessageContent(
                        doc,
                      )
                    : DefaultTextStyle(
                        style: TextStyle(
                          color: textColor,
                        ),
                        child:
                            _buildMessageContent(
                          doc,
                        ),
                      ),
              ),

              if (reactions.isNotEmpty)
                _buildReactionChips(
                  doc.id,
                  reactions,
                ),

              const SizedBox(height: 2),

              Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: pikkXGrey,
                      fontSize: 9.5,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    _buildReadStatus(data),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionChips(
    String messageId,
    Map<String, dynamic> reactions,
  ) {
    final entries = reactions.entries
        .where(
          (entry) =>
              _stringSet(
                entry.value,
              ).isNotEmpty,
        )
        .toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 3,
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 3,
        children: entries.map((entry) {
          final users =
              _stringSet(entry.value);

          return GestureDetector(
            onTap: () {
              _toggleReaction(
                messageId,
                entry.key,
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: pikkXWhite,
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: pikkXLightGrey,
                ),
              ),
              child: Text(
                '${entry.key} ${users.length}',
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReadStatus(
    Map<String, dynamic> data,
  ) {
    final read = data['read'] == true;
    final delivered =
        data['delivered'] == true;

    if (read) {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: pikkXBlack,
      );
    }

    if (delivered) {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: pikkXGrey,
      );
    }

    return const Icon(
      Icons.done_rounded,
      size: 14,
      color: pikkXGrey,
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _messageStream(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.hasError) {
          return _buildErrorState(
            'Could not load messages.',
          );
        }

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: pikkXBlack,
            ),
          );
        }

        final docs =
            snapshot.data?.docs ??
                <
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 35,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXWhite,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .chat_bubble_outline_rounded,
                      size: 30,
                      color:
                          pikkXBlack,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Start the conversation',
                    style: TextStyle(
                      color: pikkXBlack,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Send a message, picture or sticker.',
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

        return ListView.builder(
          reverse: false,
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
          padding:
              const EdgeInsets.fromLTRB(
            0,
            15,
            0,
            12,
          ),
          itemCount: docs.length,
          itemBuilder: (
            context,
            index,
          ) {
            return _buildMessageBubble(
              docs[index],
            );
          },
        );
      },
    );
  }

  Future<void> _showStickerPicker() async {
    if (!mounted ||
        _isSending ||
        _isSendingAttachment) {
      return;
    }

    final stickerEmojis = <String>[
      '😂',
      '😍',
      '🥰',
      '😭',
      '😎',
      '😳',
      '😮',
      '😢',
      '😡',
      '🤔',
      '🥹',
      '🤣',
      '😴',
      '🙄',
      '😇',
      '🤭',
      '🤩',
      '😱',
      '❤️',
      '💕',
      '💔',
      '🔥',
      '🎉',
      '👏',
      '🙏',
      '💯',
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: pikkXWhite,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              14,
              12,
              14,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: pikkXLightGrey,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Stickers',
                        style: TextStyle(
                          color: pikkXBlack,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        // IMPORTANT:
                        // This sends the selected
                        // gallery picture as a
                        // SMALL sticker message.
                        _sendGallerySticker();
                      },
                      icon: const Icon(
                        Icons
                            .photo_library_outlined,
                        color: pikkXBlack,
                        size: 20,
                      ),
                      label: const Text(
                        'Choose from Gallery',
                        style: TextStyle(
                          color: pikkXBlack,
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount:
                      stickerEmojis.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final emoji =
                        stickerEmojis[index];

                    return InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _sendSticker(
                          emoji,
                        );
                      },
                      child: Center(
                        child: Text(
                          emoji,
                          style:
                              const TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(15),
        onTap:
            _isSendingAttachment ||
                    _isSending
                ? null
                : _sendImage,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pikkXWhite,
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: pikkXLightGrey,
            ),
          ),
          child: const Icon(
            Icons
                .photo_library_outlined,
            color: pikkXBlack,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _buildStickerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(15),
        onTap:
            _isSendingAttachment ||
                    _isSending
                ? null
                : _showStickerPicker,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pikkXWhite,
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: pikkXLightGrey,
            ),
          ),
          child: const Icon(
            Icons
                .emoji_emotions_outlined,
            color: pikkXBlack,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final canSend =
        _messageController.text.trim().isNotEmpty &&
            !_isSending &&
            !_isSendingAttachment;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReplyPreview(),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              4,
              10,
              9,
            ),
            child: _glass(
              radius: 23,
              padding:
                  const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  _buildAttachmentButton(),

                  const SizedBox(width: 5),

                  // ONE sticker button only.
                  _buildStickerButton(),

                  const SizedBox(width: 6),

                  Expanded(
                    child: TextField(
                      controller:
                          _messageController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization:
                          TextCapitalization.sentences,
                      onChanged: (_) {
                        if (!mounted) return;
                        setState(() {});
                      },
                      onSubmitted: (_) {
                        if (canSend) {
                          _sendMessage();
                        }
                      },
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Write a message...',
                        hintStyle: TextStyle(
                          color: pikkXGrey,
                          fontSize: 13,
                        ),
                        border:
                            InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  Material(
                    color: canSend
                        ? pikkXBlack
                        : pikkXLightGrey,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      onTap: canSend
                          ? _sendMessage
                          : null,
                      child: SizedBox(
                        width: 45,
                        height: 45,
                        child: Icon(
                          Icons
                              .arrow_upward_rounded,
                          color: canSend
                              ? pikkXWhite
                              : pikkXGrey,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHeader() {
    final name =
        (widget.otherUserName ?? 'PikkX Chat')
            .trim();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          10,
          7,
          10,
          8,
        ),
        child: _glass(
          radius: 20,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: pikkXBlack,
                ),
              ),

              _avatarFallback(
                name,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty
                          ? 'PikkX Chat'
                          : name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: pikkXBlack,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Chat',
                      style: TextStyle(
                        color: pikkXGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  _showMessage(
                    'Chat search is available from the inbox.',
                  );
                },
                icon: const Icon(
                  Icons.search_rounded,
                  color: pikkXBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversation() {
    return Scaffold(
      backgroundColor: pikkXBackground,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildConversationHeader(),

          Expanded(
            child: _buildMessagesList(),
          ),

          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildInboxBody() {
    return Stack(
      children: [
        Column(
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
                  if (snapshot.hasError) {
                    return _buildErrorState(
                      'Could not load chats.',
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: pikkXBlack,
                      ),
                    );
                  }

                  final chats =
                      snapshot.data?.docs.toList() ??
                          <
                              QueryDocumentSnapshot<
                                  Map<String,
                                      dynamic>>>[];

                  final sorted =
                      _sortChats(chats);

                  final filtered =
                      _filterChats(sorted);

                  if (filtered.isEmpty) {
                    return _buildFilterEmptyState();
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.only(
                      top: 2,
                      bottom: 105,
                    ),
                    itemCount:
                        filtered.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      return _buildChatTile(
                        filtered[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),

        Positioned(
          right: 18,
          bottom: 18,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(19),
              onTap: _showChatSearch,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: pikkXWhite
                      .withValues(
                    alpha: 0.94,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    19,
                  ),
                  border: Border.all(
                    color: pikkXLightGrey,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 18,
                      offset:
                          const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: pikkXBlack,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterEmptyState() {
    String title = 'No chats yet';
    String subtitle =
        'Your conversations will appear here.';

    if (_selectedFilter == 1) {
      title = 'No communities';
      subtitle =
          'Community chats will appear here.';
    } else if (_selectedFilter == 2) {
      title = 'No unread chats';
      subtitle =
          'You are all caught up.';
    } else if (_selectedFilter == 3) {
      title = 'No favorite chats';
      subtitle =
          'Favorite chats will appear here.';
    } else if (_selectedFilter == 4) {
      if (_activeFolderName != null) {
        title =
            'No chats in $_activeFolderName';
      } else {
        title = 'Choose a folder';
      }

      subtitle =
          'Organize your conversations into folders.';
    }

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 35,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: pikkXWhite,
                borderRadius:
                    BorderRadius.circular(
                  23,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: pikkXBlack,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: pikkXBlack,
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: pikkXGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInState() {
    return Scaffold(
      backgroundColor: pikkXBackground,
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(30),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: pikkXBlack,
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: pikkXWhite,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to use Chat',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your PikkX conversations will appear here.',
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

  Widget _buildErrorState(
    String message,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color: pikkXGrey,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: pikkXGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glass({
    required Widget child,
    double radius = 20,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(10),
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: pikkXWhite.withValues(
              alpha: 0.82,
            ),
            borderRadius:
                BorderRadius.circular(
              radius,
            ),
            border: Border.all(
              color: pikkXWhite.withValues(
                alpha: 0.9,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.035,
                ),
                blurRadius: 16,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              pikkXBlack,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConversation) {
      return _buildConversation();
    }

    if (_userId == null) {
      return _buildSignInState();
    }

    return Scaffold(
      backgroundColor: pikkXBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: pikkXBlack,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _buildInboxBody(),
    );
  }
}
