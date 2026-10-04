import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MerchantApplicationPage extends StatefulWidget {
  const MerchantApplicationPage({super.key});

  @override
  State<MerchantApplicationPage> createState() =>
      _MerchantApplicationPageState();
}

class _MerchantApplicationPageState
    extends State<MerchantApplicationPage> {
  final _formKey = GlobalKey<FormState>();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  final _businessNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  String? _businessType;

  String _name = '';
  String _email = '';
  String? _profilePhotoUrl;
  File? _businessPhoto;

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final snapshot =
          await _firestore.collection('users').doc(user.uid).get();

      final data = snapshot.data();

      if (!mounted) return;

      setState(() {
        _name = data?['name']?.toString().trim().isNotEmpty == true
            ? data!['name'].toString().trim()
            : (user.displayName ?? '');

        _email = data?['email']?.toString().trim().isNotEmpty == true
            ? data!['email'].toString().trim()
            : (user.email ?? '');

        _profilePhotoUrl =
            data?['photoUrl']?.toString() ??
            data?['profilePhotoUrl']?.toString() ??
            user.photoURL;

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _name = user.displayName ?? '';
        _email = user.email ?? '';
        _profilePhotoUrl = user.photoURL;
        _loading = false;
      });

      _showMessage('Unable to load your profile.');
    }
  }

  Future<void> _pickBusinessPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) return;

      setState(() {
        _businessPhoto = File(image.path);
      });
    } catch (_) {
      _showMessage('Unable to select the photo.');
    }
  }

  Future<String?> _uploadBusinessPhoto(String uid) async {
    if (_businessPhoto == null) return null;

    final ref = _storage
        .ref()
        .child('merchant_applications')
        .child(uid)
        .child(
          'business_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

    final upload = await ref.putFile(
      _businessPhoto!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return upload.ref.getDownloadURL();
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.black,
          width: 1.2,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withOpacity(.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  Widget _profileAvatar() {
    if (_profilePhotoUrl != null &&
        _profilePhotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          _profilePhotoUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        ),
      );
    }

    return _defaultAvatar();
  }

  Widget _profileInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isNotEmpty ? value : 'Not available',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _submitApplication() async {
    if (_submitting) return;

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please sign in before applying.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final existing = await _firestore
          .collection('merchantApplications')
          .where('uid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;

        setState(() => _submitting = false);

        _showMessage(
          'You already have a pending merchant application.',
        );
        return;
      }

      final businessPhotoUrl =
          await _uploadBusinessPhoto(user.uid);

      final applicationRef =
          _firestore.collection('merchantApplications').doc();

      await applicationRef.set({
        'applicationId': applicationRef.id,
        'uid': user.uid,
        'businessName': _businessNameController.text.trim(),
        'businessType': _businessType,
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'businessPhone': _phoneController.text.trim(),
        'businessLocation': _locationController.text.trim(),
        'fullName': _name,
        'email': _email,
        'businessPhotoUrl': businessPhotoUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(user.uid).set({
        'merchantApplicationStatus': 'pending',
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => _submitting = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Application Submitted',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            content: const Text(
              'Your merchant application has been submitted and is now pending review.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() => _submitting = false);

      _showMessage(
        e.message ?? 'Unable to submit your application.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _submitting = false);

      _showMessage(
        'Unable to submit your application. Please try again.',
      );
    }
  }

  Widget _businessPhotoBox() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _submitting ? null : _pickBusinessPhoto,
      child: Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withOpacity(.07),
          ),
        ),
        child: _businessPhoto == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Add business photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      _businessPhoto!,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.78),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Change photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Merchant Application',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 12),

              _glassCard(
                child: Row(
                  children: [
                    _profileAvatar(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your PikkX Profile',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _name.isNotEmpty
                                ? _name
                                : 'Profile name unavailable',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Start your merchant journey',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Tell us about your business and we’ll review your application.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle(
                'Business Information',
                'Basic details about what you sell or provide.',
              ),

              _glassCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _businessNameController,
                      decoration: _decoration(
                        label: 'Business name *',
                        hint: 'Enter your business name',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your business name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _businessType,
                      decoration: _decoration(
                        label: 'Business type *',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Products',
                          child: Text('Products'),
                        ),
                        DropdownMenuItem(
                          value: 'Food',
                          child: Text('Food'),
                        ),
                        DropdownMenuItem(
                          value: 'Services',
                          child: Text('Services'),
                        ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) {
                              setState(() {
                                _businessType = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Select your business type';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _categoryController,
                      decoration: _decoration(
                        label: 'Category *',
                        hint: 'Fashion, electronics, beauty...',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your category';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _decoration(
                        label: 'Business description *',
                        hint: 'What do you sell or provide?',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Describe your business';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle(
                'Contact & Location',
                'How customers can reach your business.',
              ),

              _glassCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration(
                        label: 'Business phone number *',
                        hint: 'Enter your business phone',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your business phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _locationController,
                      decoration: _decoration(
                        label: 'Business location *',
                        hint: 'City, area or business address',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your business location';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle(
                'Merchant Information',
                'Pulled directly from your PikkX account.',
              ),

              _glassCard(
                child: Column(
                  children: [
                    _profileInfoTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Full name',
                      value: _name,
                    ),
                    const SizedBox(height: 12),
                    _profileInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: _email,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle(
                'Business Photo',
                'Add a logo or photo representing your business.',
              ),

              _glassCard(
                child: _businessPhotoBox(),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Your application will be reviewed by PikkX before you can start selling.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _submitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black45,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'By submitting, you confirm that the information provided is accurate.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
