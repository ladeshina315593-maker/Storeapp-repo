import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color pikkXBorder = Color(0xFFE8E8E8);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final ImagePicker _picker =
      ImagePicker();

  // ============================================================
  // PROFILE STATE
  // ============================================================

  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  String _name = 'Your Name';
  String _email = '';
  String _phone = '';
  String _photoUrl = '';

  int _ordersCount = 0;
  int _favouritesCount = 0;
  int _cartCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _name = 'Guest';
        _email = '';
        _phone = '';
        _photoUrl = '';
        _ordersCount = 0;
        _favouritesCount = 0;
        _cartCount = 0;
        _followingCount = 0;
      });

      return;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      // Load counts independently so one unavailable
      // collection does not break the whole profile.
      final results = await Future.wait([
        _getCollectionCount(
          'users/${user.uid}/orders',
        ),
        _getCollectionCount(
          'users/${user.uid}/favorites',
        ),
        _getCollectionCount(
          'users/${user.uid}/cart',
        ),
        _getCollectionCount(
          'users/${user.uid}/following',
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _name =
            data?['name']?.toString() ??
                user.displayName ??
                'Your Name';

        _email =
            data?['email']?.toString() ??
                user.email ??
                '';

        _phone =
            data?['phone']?.toString() ??
                user.phoneNumber ??
                '';

        _photoUrl =
            data?['photoUrl']?.toString() ??
                user.photoURL ??
                '';

        _ordersCount = results[0];
        _favouritesCount = results[1];
        _cartCount = results[2];
        _followingCount = results[3];

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Profile loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _name =
            user.displayName ??
                'Your Name';

        _email =
            user.email ?? '';

        _phone =
            user.phoneNumber ?? '';

        _photoUrl =
            user.photoURL ?? '';

        _isLoading = false;
      });
    }
  }

  Future<int> _getCollectionCount(
    String path,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(path)
              .get();

      return snapshot.size;
    } catch (e) {
      debugPrint(
        'Count loading error for $path: $e',
      );
      return 0;
    }
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
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
          padding: padding,
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.70),
            borderRadius:
                BorderRadius.circular(radius),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.95),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  0.045,
                ),
                blurRadius: 22,
                offset:
                    const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _pageHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
        ),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openSettings,
            borderRadius:
                BorderRadius.circular(15),
            child: Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(0.70),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white,
                ),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: pikkXBlack,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // YOUR PROFILE CARD
  // ============================================================

  Widget _yourProfileCard() {
    return _glassContainer(
      padding: const EdgeInsets.all(15),
      radius: 25,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openEditProfile,
          borderRadius:
              BorderRadius.circular(18),
          child: Row(
            children: [
              _profileImage(),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Profile',
                      style: TextStyle(
                        color: pikkXBlack,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: pikkXBlack,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Manage your PikkX account',
                      style: TextStyle(
                        color: pikkXGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: pikkXBlack,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: pikkXWhite,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _profileImage() {
    return GestureDetector(
      onTap: _changeProfilePicture,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 72,
            width: 72,
            padding:
                const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pikkXWhite,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(
                    0.08,
                  ),
                  blurRadius: 16,
                  offset:
                      const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: _photoUrl.isNotEmpty
                  ? Image.network(
                      _photoUrl,
                      key: ValueKey(
                        _photoUrl,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _defaultProfileIcon();
                      },
                    )
                  : _defaultProfileIcon(),
            ),
          ),

          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: pikkXBlack,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: _isUploadingPhoto
                  ? const Padding(
                      padding:
                          EdgeInsets.all(7),
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: pikkXWhite,
                      ),
                    )
                  : const Icon(
                      Icons.edit_rounded,
                      color: pikkXWhite,
                      size: 13,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultProfileIcon() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Icon(
        Icons.person_rounded,
        color: pikkXBlack,
        size: 36,
      ),
    );
  }

  // ============================================================
  // PROFILE PICTURE UPLOAD
  // ============================================================

  Future<void> _changeProfilePicture() async {
    final user = _auth.currentUser;

    if (user == null ||
        _isUploadingPhoto) {
      return;
    }

    try {
      final XFile? pickedFile =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1400,
        maxHeight: 1400,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      final file =
          File(pickedFile.path);

      // IMPORTANT:
      // Use a unique filename so Firebase gives us
      // a fresh URL instead of potentially reusing
      // the previous cached image.
      final timestamp =
          DateTime.now()
              .millisecondsSinceEpoch;

      final storageRef =
          FirebaseStorage.instance
              .ref()
              .child('profile_pictures')
              .child(
                '${user.uid}_$timestamp.jpg',
              );

      await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final downloadUrl =
          await storageRef.getDownloadURL();

      // Update Firebase Auth.
      await user.updatePhotoURL(
        downloadUrl,
      );

      // Make the Auth profile refresh.
      await user.reload();

      // Save the SAME URL in Firestore.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'photoUrl': downloadUrl,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      // Immediately update the visible profile.
      setState(() {
        _photoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });

      _showMessage(
        'Profile picture updated successfully.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Profile picture upload error: $e',
      );

      debugPrint(
        'Profile picture stack trace: '
        '$stackTrace',
      );

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      _showMessage(
        'Unable to update profile picture.',
      );
    }
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        4,
        2,
        4,
        9,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: pikkXBlack,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE OPTION
  // ============================================================

  Widget _profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool disabled = false,
    bool destructive = false,
  }) {
    final titleColor =
        destructive
            ? const Color(0xFFD32F2F)
            : pikkXBlack;

    final iconColor =
        destructive
            ? const Color(0xFFD32F2F)
            : pikkXBlack;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: _glassContainer(
        padding:
            EdgeInsets.zero,
        radius: 20,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled
                ? null
                : onTap,
            borderRadius:
                BorderRadius.circular(20),
            child: Opacity(
              opacity:
                  disabled ? 0.48 : 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 43,
                      width: 43,
                      decoration:
                          BoxDecoration(
                        color: destructive
                            ? const Color(
                                0xFFFFF0F0,
                              )
                            : Colors.black
                                .withOpacity(
                                0.055,
                              ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color:
                                  titleColor,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  pikkXGrey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (disabled)
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          right: 5,
                        ),
                        child: Text(
                          'Coming later',
                          style:
                              TextStyle(
                            color:
                                pikkXGrey,
                            fontSize: 8,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),

                    Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      color: destructive
                          ? const Color(
                              0xFFD32F2F,
                            )
                          : pikkXGrey,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOLLOWING MERCHANTS
  // ============================================================

  Widget _followingSection() {
    final user = _auth.currentUser;

    if (user == null) {
      return _glassContainer(
        radius: 23,
        padding: const EdgeInsets.all(18),
        child: const Text(
          'Sign in to see the merchants you follow.',
          style: TextStyle(
            color: pikkXGrey,
            fontSize: 11,
          ),
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.hasError) {
          debugPrint(
            'Following stream error: '
            '${snapshot.error}',
          );

          return _followingEmptyCard(
            'Following is unavailable right now.',
          );
        }

        final following =
            snapshot.data?.docs ?? [];

        if (following.isEmpty) {
          return _followingEmptyCard(
            'You’re not following any merchants yet.',
          );
        }

        return _glassContainer(
          radius: 23,
          padding:
              const EdgeInsets.all(12),
          child: Column(
            children: [
              for (
                int i = 0;
                i < following.length;
                i++
              )
                _followingMerchantTile(
                  following[i],
                  isLast:
                      i == following.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _followingEmptyCard(
    String message,
  ) {
    return _glassContainer(
      radius: 23,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color:
                  Colors.black.withOpacity(
                0.055,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: pikkXBlack,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: pikkXGrey,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _followingMerchantTile(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document, {
    required bool isLast,
  }) {
    final data =
        document.data();

    final merchantName =
        data['sellerName']?.toString() ??
            data['merchantName']?.toString() ??
            data['storeName']?.toString() ??
            'Merchant';

    final imageUrl =
        data['photoUrl']?.toString() ??
            data['merchantPhotoUrl']
                ?.toString() ??
            data['imageUrl']?.toString() ??
            '';

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _openFollowingMerchant(
                document.id,
                data,
              );
            },
            borderRadius:
                BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 7,
              ),
              child: Row(
                children: [
                  _merchantAvatar(
                    merchantName,
                    imageUrl,
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
                        Text(
                          merchantName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                pikkXBlack,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        const Text(
                          'Following',
                          style:
                              TextStyle(
                            color:
                                pikkXGrey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    height: 32,
                    width: 32,
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
                      color:
                          pikkXWhite,
                      size: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (!isLast)
          Divider(
            height: 1,
            color:
                pikkXBorder.withOpacity(
              0.75,
            ),
          ),
      ],
    );
  }

  Widget _merchantAvatar(
    String name,
    String imageUrl,
  ) {
    return Container(
      height: 47,
      width: 47,
      padding:
          const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: pikkXWhite,
        shape: BoxShape.circle,
        border: Border.all(
          color: pikkXBorder,
        ),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _merchantFallback(
                    name,
                  );
                },
              )
            : _merchantFallback(
                name,
              ),
      ),
    );
  }

  Widget _merchantFallback(
    String name,
  ) {
    return Container(
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'M',
        style: const TextStyle(
          color: pikkXBlack,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // MERCHANT ACTION
  // ============================================================

  void _openFollowingMerchant(
    String documentId,
    Map<String, dynamic> data,
  ) {
    // The following record itself is real and connected.
    // There is no invented merchant route here.
    //
    // If PikkX later has a Merchant/Store page,
    // this exact action can navigate to it.
    //
    // For now, show the stored merchant information
    // instead of creating a dead navigation button.

    final name =
        data['sellerName']?.toString() ??
            data['merchantName']?.toString() ??
            data['storeName']?.toString() ??
            'Merchant';

    final sellerId =
        data['sellerId']?.toString() ??
            data['merchantId']?.toString() ??
            documentId;

    _showMerchantDetails(
      name,
      sellerId,
    );
  }

  void _showMerchantDetails(
    String name,
    String sellerId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _glassContainer(
          radius: 28,
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration:
                        BoxDecoration(
                      color: pikkXBlack,
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color:
                          pikkXWhite,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          name,
                          style:
                              const TextStyle(
                            color:
                                pikkXBlack,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        const Text(
                          'Merchant you follow',
                          style:
                              TextStyle(
                            color:
                                pikkXGrey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                'Merchant ID: $sellerId',
                style:
                    const TextStyle(
                  color: pikkXGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openOrders() {
    Navigator.pushNamed(
      context,
      '/orders',
    );
  }

  void _openCart() {
    Navigator.pushNamed(
      context,
      '/cart',
    );
  }

  void _openAddresses() {
    Navigator.pushNamed(
      context,
      '/delivery-address',
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(
      context,
      '/notifications',
    );
  }

  void _openSettings() {
    Navigator.pushNamed(
      context,
      '/settings',
    );
  }

  // ============================================================
  // HELP & SUPPORT
  // ============================================================

  void _openHelpSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return _glassContainer(
          radius: 28,
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Help & Support',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Need help with your PikkX account, orders, delivery, or shopping?',
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 16),

              _supportRow(
                Icons.help_outline_rounded,
                'PikkX Help Center',
              ),

              _supportRow(
                Icons.chat_bubble_outline_rounded,
                'Contact Support',
              ),

              _supportRow(
                Icons.receipt_long_outlined,
                'Order Support',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _supportRow(
    IconData icon,
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              Colors.black.withOpacity(
            0.045,
          ),
          borderRadius:
              BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: pikkXBlack,
              size: 19,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style:
                  const TextStyle(
                color: pikkXBlack,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRIVACY & SECURITY
  // ============================================================

  void _openPrivacySecurity() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return _glassContainer(
          radius: 28,
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy & Security',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Your PikkX account information is protected through Firebase Authentication and your private user data is stored under your account.',
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              _securityInfo(
                Icons.verified_user_outlined,
                'Account protection',
              ),

              _securityInfo(
                Icons.lock_outline_rounded,
                'Secure authentication',
              ),

              _securityInfo(
                Icons.person_outline_rounded,
                'Private profile information',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _securityInfo(
    IconData icon,
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration:
                BoxDecoration(
              color:
                  Colors.black.withOpacity(
                0.055,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: pikkXBlack,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style:
                const TextStyle(
              color: pikkXBlack,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'No account is currently signed in.',
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              pikkXWhite,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(23),
          ),
          title: const Text(
            'Delete Account?',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: const Text(
            'This will permanently delete your PikkX account. This action cannot be undone.',
            style: TextStyle(
              color: pikkXGrey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: pikkXBlack,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFD32F2F,
                ),
                foregroundColor:
                    pikkXWhite,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      // Delete the Firestore user document.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete Firebase Authentication account.
      await user.delete();

      if (!mounted) return;

      _showMessage(
        'Account deleted.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Delete account Firebase error: '
        '${e.code} ${e.message}',
      );

      if (!mounted) return;

      if (e.code ==
          'requires-recent-login') {
        _showMessage(
          'Please sign in again before deleting your account.',
        );
      } else {
        _showMessage(
          'Unable to delete your account.',
        );
      }
    } catch (e) {
      debugPrint(
        'Delete account error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Unable to delete your account.',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _signOut() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              pikkXWhite,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(23),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: pikkXGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: pikkXBlack,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    pikkXBlack,
                foregroundColor:
                    pikkXWhite,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _auth.signOut();

      if (!mounted) return;

      await _loadProfile();

      _showMessage(
        'You have been logged out.',
      );
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Unable to log out.',
      );
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _EditProfileSheet(
          currentName: _name,
          currentPhotoUrl: _photoUrl,
          onSave: _saveProfile,
          onChangePhoto:
              _changeProfilePicture,
          isUploadingPhoto:
              _isUploadingPhoto,
        );
      },
    );
  }

  Future<void> _saveProfile(
    String name,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No authenticated user.',
      );
    }

    final cleanName =
        name.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'Name cannot be empty.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,
        'name': cleanName,
        'email':
            user.email ?? _email,
        'phone':
            user.phoneNumber ?? _phone,
        'photoUrl': _photoUrl,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await user.updateDisplayName(
      cleanName,
    );

    if (!mounted) return;

    setState(() {
      _name = cleanName;
    });

    _showMessage(
      'Profile updated successfully.',
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7F7F7),
            Color(0xFFFFFFFF),
            Color(0xFFF7F7F7),
          ],
          begin:
              Alignment.topCenter,
          end:
              Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // SOFT ORGANIC BACKGROUND
          Positioned(
            top: -70,
            right: -50,
            child: _backgroundBlob(
              190,
            ),
          ),

          Positioned(
            top: 230,
            left: -100,
            child: _backgroundBlob(
              220,
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: pikkXBlack,
                    ),
                  )
                : RefreshIndicator(
                    color:
                        pikkXBlack,
                    onRefresh:
                        _loadProfile,
                    child: ListView(
                      physics:
                          const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        18,
                        10,
                        18,
                        110,
                      ),
                      children: [
                        _pageHeader(),

                        const SizedBox(
                          height: 16,
                        ),

                        _yourProfileCard(),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==================================================
                        // SHOPPING
                        // ==================================================

                        _sectionTitle(
                          'Shopping',
                        ),

                        _profileOption(
                          icon: Icons
                              .receipt_long_rounded,
                          title:
                              'My Orders',
                          subtitle:
                              'Track and manage your orders'
                              ' ($_ordersCount)',
                          onTap:
                              _openOrders,
                        ),

                        _profileOption(
                          icon: Icons
                              .favorite_outline_rounded,
                          title:
                              'Favorites',
                          subtitle:
                              'Your saved products and services'
                              ' ($_favouritesCount)',
                          // No unknown route is invented.
                          // Use the existing MainPage
                          // bottom navigation through
                          // this direct callback.
                          onTap:
                              _openFavoritesFromProfile,
                        ),

                        _profileOption(
                          icon: Icons
                              .shopping_cart_outlined,
                          title:
                              'My Cart',
                          subtitle:
                              'Items waiting in your cart'
                              ' ($_cartCount)',
                          onTap:
                              _openCart,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ==================================================
                        // REWARDS & OFFERS
                        // Intentionally inactive per user request.
                        // ==================================================

                        _sectionTitle(
                          'Rewards & Offers',
                        ),

                        _profileOption(
                          icon: Icons
                              .confirmation_number_outlined,
                          title:
                              'Coupons',
                          subtitle:
                              'View your available coupons',
                          disabled: true,
                        ),

                        _profileOption(
                          icon: Icons
                              .card_giftcard_outlined,
                          title:
                              'Gift Cards',
                          subtitle:
                              'View and manage your gift cards',
                          disabled: true,
                        ),

                        _profileOption(
                          icon: Icons
                              .redeem_outlined,
                          title:
                              'Redeem',
                          subtitle:
                              'Redeem a gift card or promotional code',
                          disabled: true,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ==================================================
                        // PIKKX
                        // ==================================================

                        _sectionTitle(
                          'PikkX',
                        ),

                        // INTENTIONALLY INACTIVE
                        _profileOption(
                          icon: Icons
                              .storefront_outlined,
                          title:
                              'Become a Merchant',
                          subtitle:
                              'Sell products, food or services',
                          disabled: true,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ==================================================
                        // FOLLOWING
                        // ==================================================

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _sectionTitle(
                                'Following',
                              ),
                            ),
                            if (_followingCount >
                                0)
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                  right: 4,
                                ),
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal:
                                        8,
                                    vertical:
                                        4,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        pikkXBlack,
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child:
                                      Text(
                                    '$_followingCount',
                                    style:
                                        const TextStyle(
                                      color:
                                          pikkXWhite,
                                      fontSize:
                                          9,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        _followingSection(),

                        const SizedBox(
                          height: 17,
                        ),

                        // ==================================================
                        // UNLABELED: ADDRESSES
                        // ==================================================

                        _profileOption(
                          icon: Icons
                              .location_on_outlined,
                          title:
                              'Addresses',
                          subtitle:
                              'Manage your delivery addresses',
                          onTap:
                              _openAddresses,
                        ),

                        _profileOption(
                          icon: Icons
                              .notifications_none_rounded,
                          title:
                              'Notifications',
                          subtitle:
                              'Manage your notifications',
                          onTap:
                              _openNotifications,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ==================================================
                        // ACCOUNT
                        // ==================================================

                        _sectionTitle(
                          'Account',
                        ),

                        _profileOption(
                          icon: Icons
                              .settings_outlined,
                          title:
                              'Settings',
                          subtitle:
                              'Manage your app preferences',
                          onTap:
                              _openSettings,
                        ),

                        _profileOption(
                          icon: Icons
                              .shield_outlined,
                          title:
                              'Privacy & Security',
                          subtitle:
                              'Manage your account security',
                          onTap:
                              _openPrivacySecurity,
                        ),

                        _profileOption(
                          icon: Icons
                              .help_outline_rounded,
                          title:
                              'Help & Support',
                          subtitle:
                              'Get help with PikkX',
                          onTap:
                              _openHelpSupport,
                        ),

                        _profileOption(
                          icon: Icons
                              .logout_rounded,
                          title:
                              'Log Out',
                          subtitle:
                              'Sign out of your account',
                          onTap:
                              _signOut,
                        ),

                        _profileOption(
                          icon: Icons
                              .delete_outline_rounded,
                          title:
                              'Delete Account',
                          subtitle:
                              'Permanently delete your PikkX account',
                          onTap:
                              _deleteAccount,
                          destructive:
                              true,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOFT ORGANIC BLOB
  // ============================================================

  Widget _backgroundBlob(
    double size,
  ) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration:
            BoxDecoration(
          color:
              Colors.black.withOpacity(
            0.025,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  void _openFavoritesFromProfile() {
    // The profile page is embedded inside MainPage.
    // Pop to the MainPage tab if possible.
    //
    // If the app has a dedicated favorites route later,
    // this can be switched to that route.

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );

    // The MainPage owns the Favourite tab, so
    // we intentionally don't invent a /favourites route.
    //
    // If Profile is already the main tab, this keeps
    // navigation safe rather than creating a dead route.
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
          content: Text(
            message,
            style:
                const TextStyle(
              color: pikkXWhite,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          backgroundColor:
              pikkXBlack,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          elevation: 0,
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
}

// ================================================================
// EDIT PROFILE SHEET
// ================================================================

class _EditProfileSheet
    extends StatefulWidget {
  final String currentName;
  final String currentPhotoUrl;

  final Future<void> Function(
    String name,
  ) onSave;

  final Future<void> Function()
      onChangePhoto;

  final bool isUploadingPhoto;

  const _EditProfileSheet({
    required this.currentName,
    required this.currentPhotoUrl,
    required this.onSave,
    required this.onChangePhoto,
    required this.isUploadingPhoto,
  });

  @override
  State<_EditProfileSheet>
      createState() =>
          _EditProfileSheetState();
}

class _EditProfileSheetState
    extends State<_EditProfileSheet> {
  late final TextEditingController
      _nameController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
      text: widget.currentName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Please enter your name.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(name);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        'Save profile error: $e',
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Unable to update profile.',
      );
    }
  }

  Widget _sheetImage() {
    return GestureDetector(
      onTap:
          widget.isUploadingPhoto
              ? null
              : widget.onChangePhoto,
      child: Stack(
        children: [
          Container(
            height: 88,
            width: 88,
            padding:
                const EdgeInsets.all(3),
            decoration:
                BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    const Color(
                  0xFFE8E8E8,
                ),
              ),
            ),
            child: ClipOval(
              child:
                  widget.currentPhotoUrl
                          .isNotEmpty
                      ? Image.network(
                          widget.currentPhotoUrl,
                          key: ValueKey(
                            widget
                                .currentPhotoUrl,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _fallback();
                          },
                        )
                      : _fallback(),
            ),
          ),

          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 31,
              width: 31,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF050505,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color:
          const Color(0xFFF0F0F0),
      child: const Icon(
        Icons.person_rounded,
        color:
            Color(0xFF050505),
        size: 43,
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              const Color(0xFF050505),
          behavior:
              SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context)
                .viewInsets
                .bottom,
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              25,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.96),
              borderRadius:
                  const BorderRadius.vertical(
                top:
                    Radius.circular(30),
              ),
              border: Border.all(
                color: Colors.white,
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration:
                        BoxDecoration(
                      color: Colors.black
                          .withOpacity(
                        0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color:
                        Color(0xFF050505),
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Center(
                  child: Column(
                    children: [
                      _sheetImage(),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Tap the pencil to change your photo',
                        style: TextStyle(
                          color:
                              Color(0xFF777777),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                TextField(
                  controller:
                      _nameController,
                  textInputAction:
                      TextInputAction.done,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF050505),
                    fontWeight:
                        FontWeight.w600,
                  ),
                  decoration:
                      InputDecoration(
                    labelText:
                        'Name',
                    labelStyle:
                        const TextStyle(
                      color:
                          Color(0xFF777777),
                    ),
                    prefixIcon:
                        const Icon(
                      Icons
                          .person_outline_rounded,
                      color:
                          Color(0xFF050505),
                    ),
                    filled: true,
                    fillColor:
                        const Color(
                      0xFFF7F7F7,
                    ),
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

                const SizedBox(
                  height: 16,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed:
                        _saving
                            ? null
                            : _save,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF050505,
                      ),
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          const Color(
                        0xFF777777,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons
                                    .check_rounded,
                                size: 19,
                              ),
                              SizedBox(
                                width: 7,
                              ),
                              Text(
                                'Save Changes',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
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
}