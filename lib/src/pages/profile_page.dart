import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  /// These callbacks allow Profile to open the existing MainPage tabs
  /// instead of pushing duplicate Cart/Favourite screens.
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenNotifications;

  const ProfilePage({
    super.key,
    this.onOpenCart,
    this.onOpenFavorites,
    this.onOpenNotifications,
  });

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

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

  // Prevent repeated loads while the screen is already loading.
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE — OPTIMIZED
  // ============================================================

  Future<void> _loadProfile() async {
    if (_loadingProfile) return;

    _loadingProfile = true;

    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
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
      }

      _loadingProfile = false;
      return;
    }

    try {
      /*
       * IMPORTANT PERFORMANCE CHANGE:
       *
       * The old version downloaded EVERY document in:
       * orders
       * favorites
       * cart
       * following
       *
       * just to find the number of documents.
       *
       * We use Firestore count() aggregation instead.
       *
       * This is much lighter for accounts with many records.
       */

      final results = await Future.wait<dynamic>([
        _firestore
            .collection('users')
            .doc(user.uid)
            .get(),

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

      final userSnapshot =
          results[0] as DocumentSnapshot<Map<String, dynamic>>;

      final data = userSnapshot.data();

      final ordersCount = results[1] as int;
      final favouritesCount = results[2] as int;
      final cartCount = results[3] as int;
      final followingCount = results[4] as int;

      if (!mounted) return;

      setState(() {
        _name =
            data?['name']?.toString().trim().isNotEmpty == true
                ? data!['name'].toString()
                : (user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!
                    : 'Your Name');

        _email =
            data?['email']?.toString() ??
            user.email ??
            '';

        _phone =
            data?['phone']?.toString() ??
            user.phoneNumber ??
            '';

        /*
         * Support the normal PikkX field plus common existing
         * Firebase Auth data.
         */
        _photoUrl =
            data?['photoUrl']?.toString() ??
            data?['profilePicture']?.toString() ??
            user.photoURL ??
            '';

        _ordersCount = ordersCount;
        _favouritesCount = favouritesCount;
        _cartCount = cartCount;
        _followingCount = followingCount;

        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Profile loading error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      /*
       * Even if one Firebase query fails, don't leave the whole
       * Profile screen stuck on a loading spinner.
       */
      setState(() {
        _name =
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : 'Your Name';

        _email = user.email ?? '';
        _phone = user.phoneNumber ?? '';
        _photoUrl = user.photoURL ?? '';

        _isLoading = false;
      });
    } finally {
      _loadingProfile = false;
    }
  }

  Future<int> _getCollectionCount(String path) async {
    try {
      final aggregate = await _firestore
          .collection(path)
          .count()
          .get();

      return aggregate.count ?? 0;
    } catch (e) {
      /*
       * Fallback for Firebase configurations where count()
       * isn't available/usable.
       */
      debugPrint('Count error for $path: $e');

      try {
        final snapshot =
            await _firestore.collection(path).limit(500).get();

        return snapshot.size;
      } catch (_) {
        return 0;
      }
    }
  }

  // ============================================================
  // GLASS
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 24,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _yourProfileCard() {
    return _glassContainer(
      padding: const EdgeInsets.all(15),
      radius: 25,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openEditProfile,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              _profileImage(),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Profile',
                      style: TextStyle(
                        color: pikkXBlack,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: pikkXBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _email.isNotEmpty
                          ? _email
                          : 'Manage your PikkX account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: pikkXGrey,
                        fontSize: 10,
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
                  borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pikkXWhite,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: _photoUrl.isNotEmpty
                  ? Image.network(
                      _photoUrl,
                      key: ValueKey(_photoUrl),
                      fit: BoxFit.cover,

                      /*
                       * Keep the network image lightweight.
                       * The PFP is displayed at roughly 66px.
                       */
                      cacheWidth: 220,
                      cacheHeight: 220,

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
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
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
  // PROFILE PICTURE — REAL FIREBASE STORAGE
  // ============================================================

  Future<void> _changeProfilePicture() async {
    final user = _auth.currentUser;

    if (user == null || _isUploadingPhoto) {
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 900,
        maxHeight: 900,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      final file = File(pickedFile.path);

      /*
       * Use ONE stable Storage path for the user's profile picture.
       *
       * This is better than creating unlimited files:
       * uid_123.jpg
       * uid_456.jpg
       * uid_789.jpg
       *
       * Every new picture replaces the user's current PFP.
       */
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=300',
        ),
      );

      final downloadUrl =
          await storageRef.getDownloadURL();

      /*
       * Save the URL to BOTH:
       *
       * Firebase Auth
       * Firestore
       *
       * Firestore is the main PikkX profile source.
       */
      await user.updatePhotoURL(downloadUrl);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'photoUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      /*
       * Do NOT depend on user.reload() for the UI.
       *
       * We already have the verified Firebase Storage URL,
       * so update the visible UI immediately.
       */
      if (!mounted) return;

      setState(() {
        _photoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });

      _showMessage(
        'Profile picture saved successfully.',
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'Profile picture Firebase error: '
        '${e.code} ${e.message}',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      _showMessage(
        e.code == 'permission-denied'
            ? 'Firebase denied the profile picture upload.'
            : 'Unable to save profile picture.',
      );
    } catch (e, stackTrace) {
      debugPrint('Profile picture error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      _showMessage(
        'Unable to save profile picture.',
      );
    }
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
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
    bool destructive = false,
  }) {
    final titleColor = destructive
        ? const Color(0xFFD32F2F)
        : pikkXBlack;

    final iconColor = destructive
        ? const Color(0xFFD32F2F)
        : pikkXBlack;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _glassContainer(
        padding: EdgeInsets.zero,
        radius: 20,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              child: Row(
                children: [
                  Container(
                    height: 43,
                    width: 43,
                    decoration: BoxDecoration(
                      color: destructive
                          ? const Color(0xFFFFF0F0)
                          : Colors.black.withOpacity(0.055),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: pikkXGrey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: destructive
                        ? const Color(0xFFD32F2F)
                        : pikkXGrey,
                    size: 13,
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
  // SHOPPING
  // ============================================================

  void _openOrders() {
    Navigator.pushNamed(
      context,
      '/orders',
    );
  }

  void _openCart() {
    /*
     * IMPORTANT:
     * If MainPage supplies the callback, Profile opens the
     * EXISTING Cart tab rather than pushing a second Cart screen.
     */
    if (widget.onOpenCart != null) {
      widget.onOpenCart!();
      return;
    }

    /*
     * Fallback only if Profile is being used somewhere outside
     * MainPage.
     */
    Navigator.pushNamed(
      context,
      '/cart',
    );
  }

  void _openFavorites() {
    if (widget.onOpenFavorites != null) {
      widget.onOpenFavorites!();
      return;
    }

    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  void _openAddresses() {
    Navigator.pushNamed(
      context,
      '/delivery-address',
    );
  }

  void _openNotifications() {
    /*
     * Use the existing Notifications page/route.
     */
    if (widget.onOpenNotifications != null) {
      widget.onOpenNotifications!();
      return;
    }

    Navigator.pushNamed(
      context,
      '/notifications',
    );
  }

  // ============================================================
  // REWARDS & OFFERS — COUPON CODES ONLY
  // ============================================================

  Future<void> _openCoupons() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to view your coupons.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _CouponsSheet(
          firestore: _firestore,
          userId: user.uid,
        );
      },
    );
  }

  // ============================================================
  // FOLLOWING — LOAD ONLY WHEN OPENED
  // ============================================================

  Future<void> _openFollowing() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to see who you follow.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _FollowingSheet(
          firestore: _firestore,
          userId: user.uid,
          onMerchantTap: (
            documentId,
            data,
          ) {
            _showMerchantDetails(
              data,
              documentId,
            );
          },
        );
      },
    );
  }

  void _showMerchantDetails(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final name =
        data['sellerName']?.toString() ??
        data['merchantName']?.toString() ??
        data['storeName']?.toString() ??
        'Merchant';

    final sellerId =
        data['sellerId']?.toString() ??
        data['merchantId']?.toString() ??
        documentId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _glassContainer(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: pikkXBlack,
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: pikkXWhite,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: pikkXBlack,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Merchant you follow',
                          style: TextStyle(
                            color: pikkXGrey,
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
                style: const TextStyle(
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
  // HELP & SUPPORT — WHATSAPP
  // ============================================================

  Future<void> _openHelpSupport() async {
    /*
     * WhatsApp number:
     * +234 913 231 5593
     *
     * WhatsApp international format:
     * 2349132315593
     */
    final uri = Uri.parse(
      'https://wa.me/2349132315593?text=${Uri.encodeComponent(
        'Hello PikkX Support, I need help with my PikkX account.',
      )}',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage(
          'WhatsApp could not be opened.',
        );
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');

      if (!mounted) return;

      _showMessage(
        'Unable to open WhatsApp.',
      );
    }
  }

  // ============================================================
  // PRIVACY
  // ============================================================

  void _openPrivacySecurity() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _glassContainer(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.055),
              borderRadius:
                  BorderRadius.circular(12),
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
            style: const TextStyle(
              color: pikkXBlack,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE ACCOUNT — REAL FIREBASE AUTH DELETE
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
          backgroundColor: pikkXWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          title: const Text(
            'Delete Account?',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight: FontWeight.w900,
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
                  fontWeight: FontWeight.w700,
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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFD32F2F),
                foregroundColor: pikkXWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
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
      /*
       * Delete common user-owned subcollections first.
       *
       * This removes the profile's Firebase data.
       */
      await _deleteUserSubcollection(
        user.uid,
        'cart',
      );

      await _deleteUserSubcollection(
        user.uid,
        'favorites',
      );

      await _deleteUserSubcollection(
        user.uid,
        'following',
      );

      /*
       * Orders are deliberately NOT blindly deleted here.
       *
       * If your business needs order history for records,
       * those documents may need to be retained/anonymized.
       */

      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete();

      /*
       * THIS is the actual authentication-account deletion.
       */
      await user.delete();

      if (!mounted) return;

      _showMessage(
        'Your PikkX account has been deleted.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Delete account Firebase error: '
        '${e.code} ${e.message}',
      );

      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        _showMessage(
          'For security, please sign in again before deleting your account.',
        );
      } else {
        _showMessage(
          'Unable to delete your account.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Delete account error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _showMessage(
        'Unable to delete your account.',
      );
    }
  }

  Future<void> _deleteUserSubcollection(
    String uid,
    String collectionName,
  ) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection(collectionName);

      final snapshot = await ref.get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();

      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Unable to delete $collectionName: $e',
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
          backgroundColor: pikkXWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight: FontWeight.w900,
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
                  fontWeight: FontWeight.w700,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: pikkXBlack,
                foregroundColor: pikkXWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
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

      _showMessage(
        'You have been logged out.',
      );
    } catch (e) {
      debugPrint('Logout error: $e');

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _EditProfileSheet(
          currentName: _name,
          currentPhotoUrl: _photoUrl,
          onSave: _saveProfile,
          onChangePhoto: _changeProfilePicture,
          isUploadingPhoto: _isUploadingPhoto,
        );
      },
    );
  }

  Future<void> _saveProfile(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No authenticated user.',
      );
    }

    final cleanName = name.trim();

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
        'email': user.email ?? _email,
        'phone': user.phoneNumber ?? _phone,
        'photoUrl': _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
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
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7F7F7),
            Color(0xFFFFFFFF),
            Color(0xFFF7F7F7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _backgroundBlob(190),
          ),

          Positioned(
            top: 230,
            left: -100,
            child: _backgroundBlob(220),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: pikkXBlack,
                    ),
                  )
                : RefreshIndicator(
                    color: pikkXBlack,
                    onRefresh: _loadProfile,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(
                        parent:
                            BouncingScrollPhysics(),
                      ),
                      padding:
                          const EdgeInsets.fromLTRB(
                        18,
                        10,
                        18,
                        110,
                      ),
                      children: [
                        /*
                         * NO PROFILE HEADER HERE.
                         *
                         * MainPage already provides the Profile
                         * header, so this removes the duplicate.
                         */

                        _yourProfileCard(),

                        const SizedBox(height: 20),

                        // ==================================================
                        // SHOPPING
                        // ==================================================

                        _sectionTitle('Shopping'),

                        _profileOption(
                          icon:
                              Icons.receipt_long_rounded,
                          title: 'My Orders',
                          subtitle:
                              'Track and manage your orders ($_ordersCount)',
                          onTap: _openOrders,
                        ),

                        _profileOption(
                          icon:
                              Icons.favorite_outline_rounded,
                          title: 'Favorites',
                          subtitle:
                              'Your saved products ($_favouritesCount)',
                          onTap: _openFavorites,
                        ),

                        _profileOption(
                          icon:
                              Icons.shopping_cart_outlined,
                          title: 'My Cart',
                          subtitle:
                              'Items waiting in your cart ($_cartCount)',
                          onTap: _openCart,
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // REWARDS & OFFERS
                        // ==================================================

                        _sectionTitle(
                          'Rewards & Offers',
                        ),

                        /*
                         * ONLY COUPONS.
                         *
                         * Gift Cards and Redeem were removed.
                         */
                        _profileOption(
                          icon: Icons
                              .confirmation_number_outlined,
                          title: 'Coupon Codes',
                          subtitle:
                              'View your available coupon codes',
                          onTap: _openCoupons,
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // PIKKX
                        // ==================================================

                        _sectionTitle('PikkX'),

                        _profileOption(
                          icon:
                              Icons.storefront_outlined,
                          title:
                              'Become a Merchant',
                          subtitle:
                              'Sell products, food or services',
                          onTap: () {
                            _showMessage(
                              'Merchant registration is coming soon.',
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // FOLLOWING
                        // ==================================================

                        _profileOption(
                          icon:
                              Icons.people_outline_rounded,
                          title: 'Following',
                          subtitle:
                              'See who you are following ($_followingCount)',
                          onTap: _openFollowing,
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // OTHER
                        // ==================================================

                        _profileOption(
                          icon:
                              Icons.location_on_outlined,
                          title: 'Addresses',
                          subtitle:
                              'Manage your delivery addresses',
                          onTap: _openAddresses,
                        ),

                        _profileOption(
                          icon: Icons
                              .notifications_none_rounded,
                          title: 'Notifications',
                          subtitle:
                              'View your PikkX notifications',
                          onTap: _openNotifications,
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // ACCOUNT
                        // NO "SETTINGS" HEADER / NO SETTINGS OPTION
                        // ==================================================

                        _sectionTitle('Account'),

                        _profileOption(
                          icon:
                              Icons.shield_outlined,
                          title:
                              'Privacy & Security',
                          subtitle:
                              'Manage your account security',
                          onTap:
                              _openPrivacySecurity,
                        ),

                        _profileOption(
                          icon:
                              Icons.help_outline_rounded,
                          title:
                              'Help & Support',
                          subtitle:
                              'Chat with PikkX Support on WhatsApp',
                          onTap:
                              _openHelpSupport,
                        ),

                        _profileOption(
                          icon:
                              Icons.logout_rounded,
                          title: 'Log Out',
                          subtitle:
                              'Sign out of your account',
                          onTap: _signOut,
                        ),

                        _profileOption(
                          icon:
                              Icons.delete_outline_rounded,
                          title:
                              'Delete Account',
                          subtitle:
                              'Permanently delete your PikkX account',
                          onTap:
                              _deleteAccount,
                          destructive: true,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundBlob(double size) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.025),
          shape: BoxShape.circle,
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
              color: pikkXWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: pikkXBlack,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }
}

// ================================================================
// EDIT PROFILE SHEET
// ================================================================

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  final String currentPhotoUrl;

  final Future<void> Function(String name) onSave;
  final Future<void> Function() onChangePhoto;

  final bool isUploadingPhoto;

  const _EditProfileSheet({
    required this.currentName,
    required this.currentPhotoUrl,
    required this.onSave,
    required this.onChangePhoto,
    required this.isUploadingPhoto,
  });

  @override
  State<_EditProfileSheet> createState() =>
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
        e.toString().contains(
              'Name cannot be empty',
            )
            ? 'Please enter your name.'
            : 'Unable to update profile.',
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
                          cacheWidth: 240,
                          cacheHeight: 240,
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
              child:
                  widget.isUploadingPhoto
                      ? const Padding(
                          padding:
                              EdgeInsets.all(
                            7,
                          ),
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
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

  void _showMessage(String message) {
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
  Widget build(BuildContext context) {
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

// ================================================================
// COUPONS SHEET
// ================================================================

class _CouponsSheet extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String userId;

  const _CouponsSheet({
    required this.firestore,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final userRef =
        firestore.collection('users').doc(userId);

    return SafeArea(
      child: _SimpleGlassSheet(
        title: 'Coupon Codes',
        child: FutureBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          future: userRef.get(),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Padding(
                padding:
                    EdgeInsets.all(30),
                child: Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        Color(0xFF050505),
                  ),
                ),
              );
            }

            final data =
                snapshot.data?.data();

            final raw =
                data?['couponCodes'];

            final List<String> codes = [];

            if (raw is List) {
              for (final value in raw) {
                final code =
                    value.toString().trim();

                if (code.isNotEmpty) {
                  codes.add(code);
                }
              }
            }

            if (raw is String &&
                raw.trim().isNotEmpty) {
              codes.add(
                raw.trim(),
              );
            }

            if (codes.isEmpty) {
              return const Padding(
                padding:
                    EdgeInsets.all(20),
                child: Text(
                  'No coupon codes available right now.',
                  style: TextStyle(
                    color:
                        Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final code in codes)
                  Container(
                    width:
                        double.infinity,
                    margin:
                        const EdgeInsets.only(
                      bottom: 9,
                    ),
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.black
                              .withOpacity(
                        0.045,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .confirmation_number_outlined,
                          color:
                              Color(0xFF050505),
                          size: 20,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            code,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF050505,
                              ),
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing:
                                  0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// FOLLOWING SHEET
// ================================================================

class _FollowingSheet extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String userId;

  final void Function(
    String documentId,
    Map<String, dynamic> data,
  ) onMerchantTap;

  const _FollowingSheet({
    required this.firestore,
    required this.userId,
    required this.onMerchantTap,
  });

  @override
  Widget build(BuildContext context) {
    final query = firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .orderBy(
          'createdAt',
          descending: true,
        );

    return SafeArea(
      child: _SimpleGlassSheet(
        title: 'Following',
        child: StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.hasError) {
              return const Padding(
                padding:
                    EdgeInsets.all(20),
                child: Text(
                  'Unable to load your following list.',
                  style: TextStyle(
                    color:
                        Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
              );
            }

            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding:
                    EdgeInsets.all(30),
                child: Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        Color(0xFF050505),
                  ),
                ),
              );
            }

            final docs =
                snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Padding(
                padding:
                    EdgeInsets.all(20),
                child: Text(
                  'You are not following anyone yet.',
                  style: TextStyle(
                    color:
                        Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount:
                  docs.length,
              itemBuilder: (
                context,
                index,
              ) {
                final doc =
                    docs[index];

                final data =
                    doc.data();

                final name =
                    data['sellerName']
                            ?.toString() ??
                        data['merchantName']
                            ?.toString() ??
                        data['storeName']
                            ?.toString() ??
                        'Merchant';

                final imageUrl =
                    data['photoUrl']
                            ?.toString() ??
                        data['merchantPhotoUrl']
                            ?.toString() ??
                        data['imageUrl']
                            ?.toString() ??
                        '';

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Material(
                    color:
                        Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onMerchantTap(
                          doc.id,
                          data,
                        );
                      },
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          7,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 47,
                              width: 47,
                              padding:
                                  const EdgeInsets
                                      .all(
                                2,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                shape:
                                    BoxShape.circle,
                                border:
                                    Border.all(
                                  color:
                                      const Color(
                                    0xFFE8E8E8,
                                  ),
                                ),
                              ),
                              child:
                                  ClipOval(
                                child: imageUrl
                                        .isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit:
                                            BoxFit.cover,
                                        cacheWidth:
                                            180,
                                        cacheHeight:
                                            180,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return _avatarFallback(
                                            name,
                                          );
                                        },
                                      )
                                    : _avatarFallback(
                                        name,
                                      ),
                              ),
                            ),

                            const SizedBox(
                              width: 11,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    name,
                                    maxLines:
                                        1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(
                                        0xFF050505,
                                      ),
                                      fontSize:
                                          13,
                                      fontWeight:
                                          FontWeight
                                              .w800,
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
                                          Color(
                                        0xFF777777,
                                      ),
                                      fontSize:
                                          10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              color:
                                  Color(
                                0xFF777777,
                              ),
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _avatarFallback(
    String name,
  ) {
    return Container(
      color:
          const Color(0xFFF0F0F0),
      alignment:
          Alignment.center,
      child: Text(
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'M',
        style:
            const TextStyle(
          color:
              Color(0xFF050505),
          fontSize: 17,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }
}

// ================================================================
// SIMPLE GLASS SHEET
// ================================================================

class _SimpleGlassSheet
    extends StatelessWidget {
  final String title;
  final Widget child;

  const _SimpleGlassSheet({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(
        top: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          constraints:
              const BoxConstraints(
            maxHeight: 620,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white.withOpacity(
              0.96,
            ),
            borderRadius:
                const BorderRadius.vertical(
              top:
                  Radius.circular(30),
            ),
            border: Border.all(
              color:
                  Colors.white,
            ),
          ),
          child: SingleChildScrollView(
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
                      color:
                          Colors.black
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

                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF050505),
                    fontSize:
                        21,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}