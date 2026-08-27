import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;

  // Firebase-ready user information.
  //
  // These values should eventually come from:
  //
  // FirebaseAuth.instance.currentUser
  //              +
  // Firestore
  // users/{uid}
  //
  String _name = 'Your Name';
  String _email = 'your@email.com';
  String _phone = '';
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      /*
       * REAL FIREBASE STRUCTURE
       *
       * final user = FirebaseAuth.instance.currentUser;
       *
       * if (user == null) {
       *   return;
       * }
       *
       * final document = await FirebaseFirestore.instance
       *     .collection('users')
       *     .doc(user.uid)
       *     .get();
       *
       * final data = document.data();
       *
       * if (mounted && data != null) {
       *   setState(() {
       *     _name = data['name'] ?? user.displayName ?? 'User';
       *     _email = data['email'] ?? user.email ?? '';
       *     _phone = data['phone'] ?? user.phoneNumber ?? '';
       *     _photoUrl = data['photoUrl'] ?? user.photoURL ?? '';
       *   });
       * }
       */

      await Future.delayed(
        const Duration(milliseconds: 200),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _profileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        22,
      ),
      child: Row(
        children: [
          _profileImage(),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),

                if (_phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _phone,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          _editButton(),
        ],
      ),
    );
  }

  Widget _profileImage() {
    return Container(
      height: 72,
      width: 72,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.75),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.grapePurple
                .withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: _photoUrl.isNotEmpty
            ? Image.network(
                _photoUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return _defaultProfileIcon();
                },
              )
            : _defaultProfileIcon(),
      ),
    );
  }

  Widget _defaultProfileIcon() {
    return Container(
      color: AppTheme.grapeLightPurple,
      child: Icon(
        Icons.person_rounded,
        color: AppTheme.grapePurple,
        size: 38,
      ),
    );
  }

  Widget _editButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openEditProfile,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          child: Icon(
            Icons.edit_rounded,
            color: AppTheme.grapePurple,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.darkText,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: _glassContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.grapePurple
                        .withOpacity(0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.grapePurple,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.mutedText,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _EditProfileSheet(
          currentName: _name,
          onSave: (name) async {
            /*
             * REAL FIREBASE UPDATE
             *
             * final user = FirebaseAuth.instance.currentUser;
             *
             * if (user == null) return;
             *
             * await FirebaseFirestore.instance
             *     .collection('users')
             *     .doc(user.uid)
             *     .update({
             *       'name': name,
             *       'updatedAt':
             *           FieldValue.serverTimestamp(),
             *     });
             */

            if (!mounted) return;

            setState(() {
              _name = name;
            });
          },
        );
      },
    );
  }

  void _openOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Orders screen will be connected here.',
        ),
        backgroundColor: AppTheme.grapePurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddresses() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Address management will be connected here.',
        ),
        backgroundColor: AppTheme.grapePurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Settings screen will be connected here.',
        ),
        backgroundColor: AppTheme.grapePurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signOut() async {
    /*
     * REAL FIREBASE LOGOUT
     *
     * await FirebaseAuth.instance.signOut();
     *
     * After signing out, the authentication
     * state listener should send the user
     * back to LoginPage.
     */

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Firebase sign-out will be connected here.',
        ),
        backgroundColor: AppTheme.grapePurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _content() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.grapePurple,
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.grapePurple,
      onRefresh: _loadProfile,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          120,
        ),
        children: [
          _profileHeader(),

          _sectionTitle('Account'),

          _profileOption(
            icon: Icons.receipt_long_rounded,
            title: 'My Orders',
            subtitle:
                'View your previous and active orders',
            onTap: _openOrders,
          ),

          _profileOption(
            icon: Icons.location_on_outlined,
            title: 'Delivery Addresses',
            subtitle:
                'Manage your saved delivery addresses',
            onTap: _openAddresses,
          ),

          _profileOption(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle:
                'Manage your Grape Go preferences',
            onTap: _openSettings,
          ),

          const SizedBox(height: 10),

          _sectionTitle('Security'),

          _profileOption(
            icon: Icons.lock_outline_rounded,
            title: 'Password & Security',
            subtitle:
                'Manage your account security',
            onTap: () {},
          ),

          _profileOption(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle:
                'Sign out of your Grape Go account',
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.grapeLightPurple,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _content(),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  final Future<void> Function(String name) onSave;

  const _EditProfileSheet({
    Key key,
    @required this.currentName,
    @required this.onSave,
  }) : super(key: key);

  @override
  State<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState
    extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
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

    if (name.isEmpty) return;

    setState(() {
      _saving = true;
    });

    await widget.onSave(name);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                25,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        border: Border.all(
          color: Colors.white,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 45,
              decoration: BoxDecoration(
                color: AppTheme.grapeSoftPurple,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Edit Profile',
            style: TextStyle(
              color: AppTheme.darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _nameController,
            textInputAction:
                TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: AppTheme.grapePurple,
              ),
              filled: true,
              fillColor:
                  AppTheme.grapeLightPurple,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.grapePurple,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
