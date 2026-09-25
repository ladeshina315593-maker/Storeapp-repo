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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

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
  Set<String> _activeFolderChatIds = <String>{};

  // Keeps the active folder's chat list live instead of a one-off
  // snapshot, so adding/removing chats from a folder updates the
  // Folders tab immediately.
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _folderSub;

  Map<String, dynamic>? _replyTo;

  User? get _currentUser => _auth.currentUser;

  String? get _userId => _currentUser?.uid;

  bool get _isConversation =>
      widget.chatId != null && widget.chatId!.trim().isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _messagesRef {
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
      await _firestore.collection('chats').doc(widget.chatId).set(
        {
          'hiddenFor': FieldValue.arrayRemove([uid]),

          // Legacy compatibility for older chats.
          'deletedFor': FieldValue.arrayRemove([uid]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Restore chat error: $e');
    }
  }

  // ============================================================
  // MARK CHAT AS READ
  // ============================================================

  Future<void> _markChatAsRead() async {
    final uid = _userId;

    if (uid == null || !_isConversation || _isMarkingRead) {
      return;
    }

    _isMarkingRead = true;

    try {
      final chatRef =
          _firestore.collection('chats').doc(widget.chatId);

      final chatSnapshot = await chatRef.get();
      final chatData = chatSnapshot.data() ?? <String, dynamic>{};

      final participants = <String>[];

      final rawParticipants = chatData['participants'];

      if (rawParticipants is List) {
        for (final participant in rawParticipants) {
          final id = participant?.toString().trim();

          if (id != null && id.isNotEmpty) {
            participants.add(id);
          }
        }
      }

      if (!participants.contains(uid)) {
        participants.add(uid);
      }

      final unreadCounts = <String, dynamic>{
        ...?_asMap(chatData['unreadCounts']),
      };

      unreadCounts[uid] = 0;

      var totalUnread = 0;

      for (final participant in participants) {
        final count = unreadCounts[participant];

        if (count is num && count > 0) {
          totalUnread += count.toInt();
        }
      }

      await chatRef.set(
        {
          'unreadCounts': unreadCounts,
          'unreadFor': FieldValue.arrayRemove([uid]),
          'unread': totalUnread > 0,
          'unreadCount': totalUnread,
        },
        SetOptions(merge: true),
      );

      // Only fetch messages that are still unread, instead of the
      // entire message history, so this scales as a chat grows.
      final messageSnapshot =
          await _messagesRef.where('read', isEqualTo: false).get();

      final batch = _firestore.batch();
      var changed = false;

      for (final doc in messageSnapshot.docs) {
        final data = doc.data();

        final senderId = data['senderId']?.toString();

        if (senderId == null || senderId == uid) {
          continue;
        }

        final alreadyRead = data['read'] == true;
        final alreadyDelivered = data['delivered'] == true;

        if (alreadyRead && alreadyDelivered) {
          continue;
        }

        batch.update(
          doc.reference,
          {
            'delivered': true,
            'read': true,
            'deliveredAt': data['deliveredAt'] ??
                FieldValue.serverTimestamp(),
            'readAt': FieldValue.serverTimestamp(),
          },
        );

        changed = true;
      }

      if (changed) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Mark chat read error: $e');
    } finally {
      _isMarkingRead = false;
    }
  }

  // ============================================================
  // SEND TEXT
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
      final chatRef =
          _firestore.collection('chats').doc(widget.chatId);

      final messageRef = chatRef.collection('messages').doc();

      final messageData = <String, dynamic>{
        'senderId': _userId,
        'text': text,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
        'delivered': false,
        'read': false,
        'deleted': false,
        'reactions': <String, dynamic>{},
      };

      if (_replyTo != null) {
        messageData['replyTo'] = {
          'messageId': _replyTo!['messageId'],
          'senderId': _replyTo!['senderId'],
          'text': _replyTo!['text'] ?? '',
          'type': _replyTo!['type'] ?? 'text',
          'imageUrl': _replyTo!['imageUrl'],
          'stickerUrl': _replyTo!['stickerUrl'],
        };
      }

      await messageRef.set(messageData);

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
      debugPrint('Send message error: $e');
      debugPrint('Stack trace: $stackTrace');

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
      final picked = await _imagePicker.pickImage(
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

      final fileBytes = await picked.readAsBytes();

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final storageRef = _storage
          .ref()
          .child('chat_images')
          .child(widget.chatId!)
          .child('${_userId}_$timestamp.jpg');

      final uploadTask = await storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final imageUrl =
          await uploadTask.ref.getDownloadURL();

      final chatRef =
          _firestore.collection('chats').doc(widget.chatId);

      final messageRef = chatRef.collection('messages').doc();

      await messageRef.set({
        'senderId': _userId,
        'text': '',
        'type': 'image',
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'delivered': false,
        'read': false,
        'deleted': false,
        'reactions': <String, dynamic>{},
      });

      await _updateChatPreview(
        chatRef: chatRef,
        preview: '📷 Image',
      );
    } catch (e, stackTrace) {
      debugPrint('Send image error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        _showMessage('Could not send image.');
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

  /// The picker lets the user choose sticker designs using emoji
  /// as the visual source, but the actual Firestore message is an
  /// uploaded PNG image, not an emoji text message.
  Future<void> _sendSticker(String emoji) async {
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
      final stickerBytes = await _emojiToPng(emoji);

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final storageRef = _storage
          .ref()
          .child('chat_stickers')
          .child(widget.chatId!)
          .child('${_userId}_$timestamp.png');

      final uploadTask = await storageRef.putData(
        stickerBytes,
        SettableMetadata(
          contentType: 'image/png',
        ),
      );

      final stickerUrl =
          await uploadTask.ref.getDownloadURL();

      final chatRef =
          _firestore.collection('chats').doc(widget.chatId);

      final messageRef = chatRef.collection('messages').doc();

      await messageRef.set({
        'senderId': _userId,
        'text': '',
        'type': 'sticker',
        'stickerUrl': stickerUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'delivered': false,
        'read': false,
        'deleted': false,
        'reactions': <String, dynamic>{},
      });

      await _updateChatPreview(
        chatRef: chatRef,
        preview: '🎨 Sticker',
      );
    } catch (e, stackTrace) {
      debugPrint('Send sticker error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        _showMessage('Could not send sticker.');
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

  Future<Uint8List> _emojiToPng(String emoji) async {
    const size = 180.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, size, size),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(
          fontSize: 105,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();

    final image = await picture.toImage(
      size.toInt(),
      size.toInt(),
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw StateError('Could not create sticker image.');
    }

    return byteData.buffer.asUint8List();
  }

  // ============================================================
  // UPDATE CHAT PREVIEW + UNREAD
  // ============================================================

  Future<void> _updateChatPreview({
    required DocumentReference<Map<String, dynamic>> chatRef,
    required String preview,
  }) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    final chatSnapshot = await chatRef.get();
    final chatData = chatSnapshot.data() ?? <String, dynamic>{};

    final participants = <String>{};

    final rawParticipants = chatData['participants'];

    if (rawParticipants is List) {
      for (final participant in rawParticipants) {
        final id = participant?.toString().trim();

        if (id != null && id.isNotEmpty) {
          participants.add(id);
        }
      }
    }

    participants.add(uid);

    final unreadCounts = <String, dynamic>{
      ...?_asMap(chatData['unreadCounts']),
    };

    final unreadFor = <String>{};

    final existingUnreadFor = chatData['unreadFor'];

    if (existingUnreadFor is List) {
      unreadFor.addAll(
        existingUnreadFor.map((e) => e.toString()),
      );
    }

    for (final participant in participants) {
      if (participant == uid) {
        unreadCounts[participant] ??= 0;
        continue;
      }

      final oldCount = unreadCounts[participant];

      final currentCount =
          oldCount is num ? oldCount.toInt() : 0;

      unreadCounts[participant] = currentCount + 1;
      unreadFor.add(participant);
    }

    var totalUnread = 0;

    for (final value in unreadCounts.values) {
      if (value is num && value > 0) {
        totalUnread += value.toInt();
      }
    }

    await chatRef.set(
      {
        'participants': participants.toList(),
        'lastMessage': preview,
        'lastMessageSenderId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': unreadCounts,
        'unreadFor': unreadFor.toList(),
        'unread': totalUnread > 0,
        'unreadCount': totalUnread,
        'hiddenFor': FieldValue.arrayRemove([uid]),
        'deletedFor': FieldValue.arrayRemove([uid]),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // CHAT STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _chatStream() {
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortChats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  ) {
    final sorted =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      chats,
    );

    sorted.sort(
      (a, b) {
        final aDate =
            _timestampToDate(a.data()['updatedAt']);

        final bDate =
            _timestampToDate(b.data()['updatedAt']);

        return bDate.compareTo(aDate);
      },
    );

    return sorted;
  }

  DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ============================================================
  // FILTER CHAT LIST
  // ============================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterChats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  ) {
    final uid = _userId;

    if (uid == null) {
      return [];
    }

    final visibleChats = chats.where((doc) {
      final data = doc.data();

      final hiddenFor = data['hiddenFor'];

      final isHiddenForMe =
          hiddenFor is List && hiddenFor.contains(uid);

      final legacyDeletedFor = data['deletedFor'];

      final isLegacyHidden =
          legacyDeletedFor is List &&
          legacyDeletedFor.contains(uid);

      if (isHiddenForMe || isLegacyHidden) {
        return false;
      }

      return true;
    }).toList();

    if (_selectedFilter == 0) {
      return visibleChats.where((doc) {
        final data = doc.data();

        final type =
            data['type']?.toString().toLowerCase();

        return type != 'community' &&
            data['isCommunity'] != true;
      }).toList();
    }

    if (_selectedFilter == 1) {
      return visibleChats.where((doc) {
        final data = doc.data();

        final type =
            data['type']?.toString().toLowerCase();

        return type == 'community' ||
            data['isCommunity'] == true;
      }).toList();
    }

    if (_selectedFilter == 2) {
      return visibleChats.where((doc) {
        return _getUnreadCount(doc.data()) > 0;
      }).toList();
    }

    if (_selectedFilter == 3) {
      return visibleChats.where((doc) {
        final data = doc.data();

        final favoriteFor = data['favoriteFor'];

        return favoriteFor is List &&
            favoriteFor.contains(uid);
      }).toList();
    }

    if (_selectedFilter == 4) {
      if (_activeFolderId == null) {
        return [];
      }

      return visibleChats.where((doc) {
        return _activeFolderChatIds.contains(doc.id);
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

    await _firestore.collection('chats').doc(chatId).set(
      {
        'favoriteFor': value
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
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

    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: pikkXWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Create folder',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Sellers, Friends, Orders...',
              filled: true,
              fillColor: pikkXBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pikkXBlack,
                foregroundColor: pikkXWhite,
              ),
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage('Folder created.');
      }
    } catch (e) {
      debugPrint('Create folder error: $e');

      if (mounted) {
        _showMessage('Could not create folder.');
      }
    }
  }

  // Subscribes to a single chat folder document so the Folders tab
  // stays live: adding or removing a chat from the folder (from
  // anywhere) updates _activeFolderChatIds without needing to
  // reopen the folder menu.
  void _subscribeToFolder(String folderId, String fallbackName) {
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

      final data = snapshot.data() ?? <String, dynamic>{};

      final rawIds = data['chatIds'];

      final ids = <String>{};

      if (rawIds is List) {
        ids.addAll(rawIds.map((e) => e.toString()));
      }

      setState(() {
        _activeFolderName =
            data['name']?.toString() ?? fallbackName;
        _activeFolderChatIds = ids;
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.35,
            maxChildSize: 0.88,
            builder: (_, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: pikkXWhite,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _sheetHandle(),
                    const SizedBox(height: 14),
                    const Text(
                      'Chat folders',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      // Live stream instead of a one-off get(), so
                      // a newly created folder appears right away.
                      child: StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firestore
                            .collection('users')
                            .doc(uid)
                            .collection('chatFolders')
                            .orderBy('createdAt', descending: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: pikkXBlack,
                              ),
                            );
                          }

                          final docs =
                              snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(25),
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration:
                                          BoxDecoration(
                                        color: pikkXBlack
                                            .withOpacity(
                                          0.06,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          20,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons
                                            .folder_rounded,
                                        color: pikkXBlack,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    const Text(
                                      'No folders yet',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    const Text(
                                      'Create folders for Sellers, Friends, Orders and more.',
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

                          return ListView.separated(
                            controller: controller,
                            padding:
                                const EdgeInsets.fromLTRB(
                              14,
                              8,
                              14,
                              12,
                            ),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final folder = docs[index];
                              final data = folder.data();

                              final name =
                                  data['name']?.toString() ??
                                      'Folder';

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

                              final selected =
                                  _activeFolderId ==
                                      folder.id;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(
                                    17,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = 4;
                                      _activeFolderId =
                                          folder.id;
                                      _activeFolderName =
                                          name;
                                      _activeFolderChatIds =
                                          ids;
                                    });

                                    _subscribeToFolder(
                                      folder.id,
                                      name,
                                    );

                                    Navigator.pop(
                                      sheetContext,
                                    );
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
                                      color: selected
                                          ? pikkXBlack
                                          : pikkXBackground,
                                      borderRadius:
                                          BorderRadius
                                              .circular(17),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration:
                                              BoxDecoration(
                                            color: selected
                                                ? Colors
                                                    .white
                                                    .withOpacity(
                                                    0.12,
                                                  )
                                                : pikkXWhite,
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              13,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons
                                                .folder_rounded,
                                            color: selected
                                                ? pikkXWhite
                                                : pikkXBlack,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 11,
                                        ),
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style: TextStyle(
                                              color: selected
                                                  ? pikkXWhite
                                                  : pikkXBlack,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${ids.length}',
                                          style: TextStyle(
                                            color: selected
                                                ? Colors
                                                    .white70
                                                : pikkXGrey,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
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
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        0,
                        14,
                        14,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pikkXBlack,
                            foregroundColor: pikkXWhite,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _createChatFolder();
                          },
                          icon: const Icon(
                            Icons.create_new_folder_rounded,
                            size: 19,
                          ),
                          label: const Text(
                            'Create folder',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
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
      final folders = await _firestore
          .collection('users')
          .doc(uid)
          .collection('chatFolders')
          .get();

      if (!mounted) {
        return;
      }

      if (folders.docs.isEmpty) {
        _showMessage('Create a folder first.');
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 520,
              ),
              decoration: const BoxDecoration(
                color: pikkXWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  18,
                ),
                itemCount: folders.docs.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(4, 5, 4, 5),
                      child: Text(
                        'Add to folder',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }

                  final folder = folders.docs[index - 1];
                  final data = folder.data();

                  final name =
                      data['name']?.toString() ?? 'Folder';

                  final rawIds = data['chatIds'];

                  final existing =
                      rawIds is List &&
                      rawIds.contains(chatId);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: () async {
                        try {
                          await folder.reference.update({
                            'chatIds': existing
                                ? FieldValue.arrayRemove([chatId])
                                : FieldValue.arrayUnion([chatId]),
                            'updatedAt':
                                FieldValue.serverTimestamp(),
                          });

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
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
                            const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: pikkXBackground,
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: pikkXWhite,
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.folder_rounded,
                                color: pikkXBlack,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              existing
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: pikkXBlack,
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
      debugPrint('Folder picker error: $e');

      if (mounted) {
        _showMessage('Could not load folders.');
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
      await _firestore.collection('chats').doc(chatId).set(
        {
          'hiddenFor': FieldValue.arrayUnion([uid]),

          // Keep this temporarily for old data compatibility.
          'deletedFor': FieldValue.arrayUnion([uid]),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        _showMessage('Chat hidden from your inbox.');
      }
    } catch (e) {
      debugPrint('Delete chat error: $e');

      if (mounted) {
        _showMessage('Could not hide chat.');
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
    final participants = data['participants'];

    if (uid == null || participants is! List) {
      return null;
    }

    for (final id in participants) {
      final value = id.toString();

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
    final otherUid = _otherUserId(data);

    if (uid == null || otherUid == null) {
      if (mounted) {
        _showMessage('Could not identify this user.');
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

  // ============================================================
  // REPORT
  // ============================================================

  Future<void> _reportChat(
    String chatId,
    Map<String, dynamic> data,
  ) async {
    final uid = _userId;
    final otherUid = _otherUserId(data);

    if (uid == null || otherUid == null) {
      if (mounted) {
        _showMessage('Could not identify this user.');
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
        'reportedAt': FieldValue.serverTimestamp(),
        'type': 'chat',
      });

      if (mounted) {
        _showMessage('Report submitted.');
      }
    } catch (e) {
      debugPrint('Report chat error: $e');

      if (mounted) {
        _showMessage('Could not submit report.');
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
        data['otherUserName']?.toString() ??
        data['chatName']?.toString() ??
        data['name']?.toString();

    final lastMessage =
        data['lastMessage']?.toString().trim() ??
        'Start a conversation';

    final displayName =
        name == null || name.isEmpty ? 'Chat' : name;

    final unreadCount = _getUnreadCount(data);

    final isCommunity =
        data['type']?.toString().toLowerCase() == 'community' ||
        data['isCommunity'] == true;

    final favoriteFor = data['favoriteFor'];

    final isFavorite =
        favoriteFor is List &&
        _userId != null &&
        favoriteFor.contains(_userId);

    return GestureDetector(
      onLongPress: () {
        _showChatActions(chatId, data);
      },
      child: _glass(
        radius: 21,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _openChat(chatId, name);
            },
            borderRadius: BorderRadius.circular(21),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                ),
                              ),
                            ),
                            if (isFavorite)
                              const Padding(
                                padding: EdgeInsets.only(
                                  left: 5,
                                ),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: pikkXBlack,
                                  size: 15,
                                ),
                              ),
                            if (unreadCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                ),
                                child:
                                    _unreadBadge(
                                  unreadCount,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage.isEmpty
                              ? 'Start a conversation'
                              : lastMessage,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 11.5,
                            fontWeight: unreadCount > 0
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
                    decoration: BoxDecoration(
                      color: pikkXBlack,
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: pikkXWhite,
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

    final favoriteFor = data['favoriteFor'];

    final isFavorite =
        favoriteFor is List &&
        favoriteFor.contains(uid);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.58,
            minChildSize: 0.35,
            maxChildSize: 0.88,
            builder: (_, controller) {
              return _glass(
                radius: 27,
                padding: EdgeInsets.zero,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    10,
                    12,
                    18,
                  ),
                  children: [
                    _sheetHandle(),
                    const SizedBox(height: 12),
                    _actionTile(
                      icon: isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      label: isFavorite
                          ? 'Remove from Favorite'
                          : 'Favorite',
                      onTap: () async {
                        Navigator.pop(sheetContext);

                        await _setFavorite(
                          chatId,
                          !isFavorite,
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons.folder_rounded,
                      label: 'Add to folder',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showFolderPicker(chatId);
                      },
                    ),
                    _actionTile(
                      icon: Icons.notifications_off_rounded,
                      label: 'Mute',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showMessage(
                          'Mute will be added next.',
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons.push_pin_rounded,
                      label: 'Pin',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showMessage(
                          'Pin will be added next.',
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete chat for me',
                      destructive: true,
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _deleteChatForMe(chatId);
                      },
                    ),
                    _actionTile(
                      icon: Icons.block_rounded,
                      label: 'Block',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _blockUser(
                          chatId,
                          data,
                        );
                      },
                    ),
                    _actionTile(
                      icon:
                          Icons.report_problem_outlined,
                      label: 'Report',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _reportChat(
                          chatId,
                          data,
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons.close_rounded,
                      label: 'Cancel',
                      onTap: () {
                        Navigator.pop(sheetContext);
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
        decoration: BoxDecoration(
          color: pikkXGrey.withOpacity(0.4),
          borderRadius: BorderRadius.circular(5),
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
      final unreadCounts = _asMap(
        data['unreadCounts'],
      );

      final personalCount =
          unreadCounts?[uid];

      if (personalCount is num &&
          personalCount > 0) {
        return personalCount.toInt();
      }
    }

    final legacyCount = data['unreadCount'];

    if (legacyCount is num &&
        legacyCount > 0) {
      return legacyCount.toInt();
    }

    if (data['unread'] == true) {
      return 1;
    }

    final unreadFor = data['unreadFor'];

    if (unreadFor is List &&
        uid != null &&
        unreadFor.contains(uid)) {
      return 1;
    }

    return 0;
  }

  Widget _unreadBadge(int count) {
    return Container(
      constraints:
          const BoxConstraints(minWidth: 20),
      height: 20,
      padding:
          const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: pikkXWhite,
          fontSize: 9,
          fontWeight: FontWeight.w900,
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
  // INBOX
  // ============================================================

  Widget _buildInbox() {
    return Scaffold(
      backgroundColor: pikkXBackground,
      body: _userId == null
          ? _buildSignInState()
          : Stack(
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
                                'No chats yet',
                                'Your conversations with sellers and support will appear here.',
                                Icons.chat_bubble_outline_rounded,
                              );
                            }

                            if (_selectedFilter == 1) {
                              return _buildFilterEmptyState(
                                'No community chats',
                                'Community conversations will appear here.',
                                Icons.groups_rounded,
                              );
                            }

                            if (_selectedFilter == 2) {
                              return _buildFilterEmptyState(
                                'No unread chats',
                                'You are all caught up.',
                                Icons.mark_chat_read_rounded,
                              );
                            }

                            if (_selectedFilter == 3) {
                              return _buildFilterEmptyState(
                                'No favorite chats',
                                'Favorite conversations will appear here.',
                                Icons.star_border_rounded,
                              );
                            }

                            if (_selectedFilter == 4 &&
                                _activeFolderId == null) {
                              return _buildFilterEmptyState(
                                'Choose a folder',
                                'Tap the Folders pill to view or create a chat folder.',
                                Icons.folder_rounded,
                              );
                            }

                            return _buildFilterEmptyState(
                              _activeFolderName ??
                                  'Empty folder',
                              'Chats added to this folder will appear here.',
                              Icons.folder_open_rounded,
                            );
                          }

                          return ListView.builder(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              105,
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

                // Floating search button above bottom navigation.
                Positioned(
                  right: 18,
                  bottom: 18,
                  child: GestureDetector(
                    onTap: _showChatSearch,
                    child: _glass(
                      radius: 18,
                      padding:
                          const EdgeInsets.all(14),
                      child: const Icon(
                        Icons.search_rounded,
                        color: pikkXBlack,
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
            children: [
              _filterButton(
                label: 'Chat',
                index: 0,
                icon: Icons.chat_bubble_rounded,
              ),
              _filterButton(
                label: 'Communities',
                index: 1,
                icon: Icons.groups_rounded,
              ),
              _filterButton(
                label: 'Unread',
                index: 2,
                icon: Icons.mark_email_unread_rounded,
              ),
              _filterButton(
                label: 'Favorite',
                index: 3,
                icon: Icons.star_rounded,
              ),
              _filterButton(
                label: 'Folders',
                index: 4,
                icon: Icons.folder_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final selected = _selectedFilter == index;

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          _showFolderMenu();
          return;
        }

        setState(() {
          _selectedFilter = index;

          if (index != 4) {
            _activeFolderId = null;
            _activeFolderName = null;
            _activeFolderChatIds = <String>{};
            _folderSub?.cancel();
            _folderSub = null;
          }
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        margin:
            const EdgeInsets.symmetric(horizontal: 2),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        height: 39,
        decoration: BoxDecoration(
          color: selected
              ? pikkXBlack
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? pikkXWhite
                  : pikkXGrey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? pikkXWhite
                    : pikkXGrey,
                fontSize: 10,
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _showChatSearch() {
    _searchController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return SafeArea(
              child: Container(
                height:
                    MediaQuery.of(context).size.height * 0.78,
                decoration:
                    const BoxDecoration(
                  color: pikkXWhite,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _sheetHandle(),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Search chats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                      child: _glass(
                        radius: 17,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: pikkXGrey,
                              size: 21,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: TextField(
                                controller:
                                    _searchController,
                                autofocus: true,
                                onChanged: (_) {
                                  setSheetState(() {});
                                },
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'Search name or chat name...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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

                          final query =
                              _searchController.text
                                  .trim()
                                  .toLowerCase();

                          final docs =
                              snapshot.data?.docs ?? [];

                          final results = docs.where((doc) {
                            final data = doc.data();

                            final hiddenFor =
                                data['hiddenFor'];

                            final deletedFor =
                                data['deletedFor'];

                            if (hiddenFor is List &&
                                _userId != null &&
                                hiddenFor.contains(_userId)) {
                              return false;
                            }

                            if (deletedFor is List &&
                                _userId != null &&
                                deletedFor.contains(_userId)) {
                              return false;
                            }

                            if (query.isEmpty) {
                              return true;
                            }

                            final name =
                                data['otherUserName']
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';

                            final chatName =
                                data['chatName']
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';

                            final sellerName =
                                data['sellerName']
                                        ?.toString()
                                        .toLowerCase() ??
                                    '';

                            return name.contains(query) ||
                                chatName.contains(query) ||
                                sellerName.contains(query);
                          }).toList();

                          if (results.isEmpty) {
                            return _buildFilterEmptyState(
                              'No results',
                              'No chat matches your search.',
                              Icons.search_off_rounded,
                            );
                          }

                          final sorted =
                              _sortChats(results);

                          return ListView.builder(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              15,
                              5,
                              15,
                              18,
                            ),
                            itemCount: sorted.length,
                            itemBuilder:
                                (context, index) {
                              final doc =
                                  sorted[index];

                              final data =
                                  doc.data();

                              final name =
                                  data['otherUserName']
                                      ?.toString() ??
                                  data['chatName']
                                      ?.toString();

                              final displayName =
                                  name == null ||
                                          name.isEmpty
                                      ? 'Chat'
                                      : name;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 8,
                                ),
                                child: _glass(
                                  radius: 18,
                                  padding:
                                      EdgeInsets.zero,
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.pop(
                                        sheetContext,
                                      );

                                      _openChat(
                                        doc.id,
                                        displayName,
                                      );
                                    },
                                    leading:
                                        _chatAvatar(
                                      displayName,
                                    ),
                                    title: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      data['lastMessage']
                                              ?.toString() ??
                                          'Start a conversation',
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                    trailing:
                                        const Icon(
                                      Icons
                                          .arrow_forward_ios_rounded,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                style: const TextStyle(
                  color: pikkXBlack,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
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
              stream:
                  _messagesRef.snapshots(),
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
                    snapshot.data?.docs ?? [];

                final messages = rawMessages
                    .where((doc) {
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
                    })
                    .toList();

                messages.sort(
                  (a, b) {
                    final aDate =
                        _timestampToDate(
                      a.data()['createdAt'],
                    );

                    final bDate =
                        _timestampToDate(
                      b.data()['createdAt'],
                    );

                    return aDate.compareTo(bDate);
                  },
                );

                final hasUnreadIncoming =
                    messages.any((doc) {
                  final data =
                      doc.data();

                  return data['senderId'] !=
                          _userId &&
                      data['read'] != true;
                });

                if (hasUnreadIncoming &&
                    !_isMarkingRead) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (mounted) {
                      _markChatAsRead();
                    }
                  });
                }

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
        _asMap(message['reactions']) ??
            <String, dynamic>{};

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
                    type == 'image' ||
                            type == 'sticker'
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
                            .withOpacity(0.16)
                        : Colors.white
                            .withOpacity(0.9),
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
              if (isMine)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 4,
                    right: 4,
                  ),
                  child:
                      _buildMessageStatus(
                    doc,
                    message,
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
  // MESSAGE STATUS
  // ============================================================

  Widget _buildMessageStatus(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
    Map<String, dynamic> message,
  ) {
    if (doc.metadata.hasPendingWrites) {
      return const Icon(
        Icons.access_time_rounded,
        size: 15,
        color: Colors.white70,
      );
    }

    if (message['read'] == true) {
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Colors.lightBlueAccent,
      );
    }

    if (message['delivered'] == true) {
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Colors.white,
      );
    }

    return const Icon(
      Icons.done_rounded,
      size: 15,
      color: Colors.white,
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
          message['imageUrl']?.toString();

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
                Icons.broken_image_outlined,
                color: pikkXGrey,
                size: 35,
              ),
            );
          },
        ),
      );
    }

    if (type == 'sticker') {
      final stickerUrl =
          message['stickerUrl']?.toString();

      if (stickerUrl == null ||
          stickerUrl.isEmpty) {
        return const Text(
          'Sticker unavailable',
          style: TextStyle(
            color: pikkXGrey,
            fontSize: 13,
          ),
        );
      }

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(18),
        child: Image.network(
          stickerUrl,
          width: 145,
          height: 145,
          fit: BoxFit.contain,
          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return const SizedBox(
              width: 145,
              height: 145,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: pikkXGrey,
                  size: 30,
                ),
              ),
            );
          },
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
  // REPLY PREVIEW
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

    final previewText =
        replyType == 'image'
            ? '📷 Image'
            : replyType == 'sticker'
                ? '🎨 Sticker'
                : replyText.isEmpty
                    ? 'Message'
                    : replyText;

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
            ? pikkXWhite.withOpacity(0.08)
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
              previewText,
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
  // REACTIONS
  // ============================================================

  Widget _buildReactions(
    Map<String, dynamic> reactions,
    String messageId,
    bool isMine,
  ) {
    final emojis = reactions.values
        .map((value) => value?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (emojis.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        _showReactionPicker(messageId);
      },
      child: Container(
        margin:
            const EdgeInsets.only(top: 3),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color: Colors.white.withOpacity(0.95),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...emojis.take(6).map(
                  (emoji) => Padding(
                    padding:
                        const EdgeInsets.symmetric(
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
  // MESSAGE ACTIONS
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.40,
            maxChildSize: 0.92,
            builder: (_, controller) {
              return _glass(
                radius: 27,
                padding: EdgeInsets.zero,
                child: ListView(
                  controller: controller,
                  padding:
                      const EdgeInsets.fromLTRB(
                    12,
                    10,
                    12,
                    18,
                  ),
                  children: [
                    _sheetHandle(),
                    const SizedBox(height: 10),
                    _quickReactionRow(doc.id),
                    const Divider(height: 20),
                    _actionTile(
                      icon: Icons.reply_rounded,
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
                                .trim()
                                .isNotEmpty ??
                            false))
                      _actionTile(
                        icon: Icons.copy_rounded,
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
                      icon: Icons.delete_outline_rounded,
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
              );
            },
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
      '🤣',
      '😍',
      '🥰',
      '😮',
      '😢',
      '😭',
      '😡',
      '👍',
      '👎',
      '👏',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
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
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.55),
                borderRadius:
                    BorderRadius.circular(13),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.85),
                ),
              ),
              child: Text(
                emoji,
                style:
                    const TextStyle(
                  fontSize: 19,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // FULLER REACTION PICKER
  // ============================================================

  void _showReactionPicker(
    String messageId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        const reactions = <String>[
          '❤️',
          '🩷',
          '🧡',
          '💛',
          '💚',
          '💙',
          '🩵',
          '💜',
          '🤎',
          '🖤',
          '🩶',
          '🤍',
          '💔',
          '❤️‍🔥',
          '❣️',
          '💕',
          '💞',
          '💓',
          '💗',
          '💖',
          '💘',
          '💝',
          '✨',
          '⭐',
          '🌟',
          '🔥',
          '💯',
          '🎉',
          '🎊',
          '👏',
          '🙌',
          '🫶',
          '👍',
          '👎',
          '👌',
          '✌️',
          '🤞',
          '🙏',
          '💪',
          '👋',
          '😂',
          '🤣',
          '😅',
          '😆',
          '😁',
          '😄',
          '😃',
          '😀',
          '🥹',
          '🥰',
          '😍',
          '🤩',
          '😘',
          '😗',
          '☺️',
          '😊',
          '😇',
          '🙂',
          '🙃',
          '😉',
          '😌',
          '😎',
          '🤓',
          '🥳',
          '🤭',
          '🫢',
          '🤗',
          '😳',
          '😮',
          '😯',
          '😲',
          '😱',
          '😢',
          '😭',
          '🥺',
          '😔',
          '😞',
          '😕',
          '🙁',
          '☹️',
          '😣',
          '😖',
          '😫',
          '😩',
          '🥲',
          '😡',
          '😠',
          '🤬',
          '🤔',
          '🫡',
          '🫠',
          '🤯',
          '😴',
          '🤤',
          '🤪',
          '😜',
          '😝',
          '😋',
          '🤤',
          '😵',
          '🤢',
          '🤮',
          '🥶',
          '🥵',
          '💀',
          '👀',
          '💫',
          '💥',
          '💦',
          '💨',
          '✅',
          '❌',
          '❗',
          '❓',
          '‼️',
          '⁉️',
          '🎯',
          '🏆',
          '🥇',
          '👏',
          '🙈',
          '🙉',
          '🙊',
        ];

        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            builder: (_, controller) {
              return _glass(
                radius: 27,
                padding: EdgeInsets.zero,
                child: GridView.builder(
                  controller: controller,
                  padding:
                      const EdgeInsets.fromLTRB(
                    14,
                    12,
                    14,
                    18,
                  ),
                  itemCount:
                      reactions.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                    childAspectRatio: 1,
                  ),
                  itemBuilder:
                      (context, index) {
                    final emoji =
                        reactions[index];

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
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.62),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                          border: Border.all(
                            color: Colors.white
                                .withOpacity(0.85),
                          ),
                        ),
                        alignment:
                            Alignment.center,
                        child: Text(
                          emoji,
                          style:
                              const TextStyle(
                            fontSize: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
              snapshot.data() ??
                  <String, dynamic>{};

          final currentReactions =
              <String, dynamic>{
            ...?_asMap(
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
  // COPY
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
        'senderId': message['senderId'],
        'text': message['text'] ?? '',
        'type': message['type'] ?? 'text',
        'imageUrl': message['imageUrl'],
        'stickerUrl': message['stickerUrl'],
      };
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
    });
  }

  // ============================================================
  // DELETE MESSAGE FOR ME
  // ============================================================

  Future<void> _deleteForMe(
    String messageId,
  ) async {
    final uid = _userId;

    if (uid == null) {
      return;
    }

    try {
      await _messagesRef.doc(messageId).set(
        {
          'deletedFor': FieldValue.arrayUnion([
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
  // DELETE MESSAGE FOR EVERYONE
  // ============================================================

  Future<void> _deleteForEveryone(
    String messageId,
  ) async {
    try {
      await _messagesRef.doc(messageId).set(
        {
          'deleted': true,
          'text': '',
          'type': 'text',
          'imageUrl': FieldValue.delete(),
          'stickerUrl': FieldValue.delete(),
          // Clear reactions too, so a deleted bubble can't still
          // show old emoji reactions underneath it.
          'reactions': <String, dynamic>{},
          'deletedAt': FieldValue.serverTimestamp(),
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
        _replyTo!['type']?.toString() ??
            'text';

    final replyText =
        _replyTo!['text']?.toString() ??
            '';

    final previewText =
        replyType == 'image'
            ? '📷 Image'
            : replyType == 'sticker'
                ? '🎨 Sticker'
                : replyText.isEmpty
                    ? 'Message'
                    : replyText;

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
                  previewText,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
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
  // ATTACHMENTS
  // ============================================================

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                  _sheetHandle(),
                  const SizedBox(height: 8),
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
    const stickers = [
      '😂',
      '🤣',
      '❤️',
      '😍',
      '🥰',
      '🔥',
      '😎',
      '🥳',
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
      '😭',
      '🥺',
      '🤭',
      '😜',
      '😴',
      '🤯',
      '💖',
      '⭐',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                            .withOpacity(0.58),
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
  // EMPTY STATES
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
                  borderRadius:
                      BorderRadius.circular(22),
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
                Icons.error_outline_rounded,
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
  // GLASS
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
        filter: ui.ImageFilter.blur(
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
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

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
                  style:
                      const TextStyle(
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