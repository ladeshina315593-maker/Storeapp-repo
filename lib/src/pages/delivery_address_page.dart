import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({super.key});

  @override
  State<DeliveryAddressPage> createState() =>
      _DeliveryAddressPageState();
}

class _DeliveryAddressPageState
    extends State<DeliveryAddressPage> {
  // ============================================================
  // pikkX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color background = Color(0xFFF7F7F7);
  static const Color darkBackground = Color(0xFF050505);
  static const Color muted = Color(0xFF73777D);
  static const Color softGrey = Color(0xFFE8E8E8);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController _fullNameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _stateController =
      TextEditingController();

  final TextEditingController _countryController =
      TextEditingController(text: 'Nigeria');

  bool isLoading = true;
  bool isSaving = false;

  List<Map<String, dynamic>> addresses = [];

  String? editingAddressId;

  String? get userId => _auth.currentUser?.uid;

  // ============================================================
  // FIRESTORE
  //
  // users/{uid}/addresses/{addressId}
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get addressesRef {
    final uid = userId;

    if (uid == null) {
      throw StateError(
        'User must be authenticated before accessing addresses.',
      );
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses');
  }

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD ADDRESSES
  // ============================================================

  Future<void> _loadAddresses() async {
    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await addressesRef
          .orderBy('createdAt', descending: true)
          .get();

      final loaded = snapshot.docs.map((doc) {
        return <String, dynamic>{
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        addresses = loaded;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load addresses error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Unable to load your saved addresses.',
      );
    }
  }

  // ============================================================
  // OPEN ADD / EDIT FORM
  // ============================================================

  void _openAddressForm({
    Map<String, dynamic>? address,
  }) {
    editingAddressId =
        address?['id']?.toString();

    _fullNameController.text =
        address?['fullName']?.toString() ?? '';

    _phoneController.text =
        address?['phone']?.toString() ?? '';

    _addressController.text =
        address?['addressLine']?.toString() ?? '';

    _cityController.text =
        address?['city']?.toString() ?? '';

    _stateController.text =
        address?['state']?.toString() ?? '';

    _countryController.text =
        address?['country']?.toString() ?? 'Nigeria';

    bool isDefault =
        address?['isDefault'] == true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _glassContainer(
                radius: 30,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: pikkXBlack.withOpacity(0.18),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address == null
                                  ? 'Add delivery address'
                                  : 'Edit delivery address',
                              style: const TextStyle(
                                color: pikkXBlack,
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: pikkXBlack,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _formField(
                        controller:
                            _fullNameController,
                        label: 'Full name',
                        hint:
                            'Name of the person receiving the order',
                        icon:
                            Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 13),

                      _formField(
                        controller:
                            _phoneController,
                        label: 'Phone number',
                        hint:
                            'Phone number for delivery',
                        icon:
                            Icons.phone_outlined,
                        keyboardType:
                            TextInputType.phone,
                      ),

                      const SizedBox(height: 13),

                      _formField(
                        controller:
                            _addressController,
                        label: 'Street / house address',
                        hint:
                            'House number, street, area, landmark',
                        icon:
                            Icons.location_on_outlined,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 13),

                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              controller:
                                  _cityController,
                              label: 'City',
                              hint: 'City',
                              icon:
                                  Icons.location_city_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _formField(
                              controller:
                                  _stateController,
                              label: 'State',
                              hint: 'State',
                              icon:
                                  Icons.map_outlined,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 13),

                      _formField(
                        controller:
                            _countryController,
                        label: 'Country',
                        hint: 'Country',
                        icon:
                            Icons.public_outlined,
                      ),

                      const SizedBox(height: 8),

                      CheckboxListTile(
                        value: isDefault,
                        onChanged: (value) {
                          setModalState(() {
                            isDefault =
                                value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: pikkXNavy,
                        checkColor: pikkXWhite,
                        controlAffinity:
                            ListTileControlAffinity.leading,
                        title: const Text(
                          'Use as my default address',
                          style: TextStyle(
                            color: pikkXBlack,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final success =
                                      await _saveAddress(
                                    isDefault:
                                        isDefault,
                                  );

                                  if (success &&
                                      sheetContext.mounted) {
                                    Navigator.pop(
                                      sheetContext,
                                    );
                                  }
                                },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                pikkXBlack,
                            foregroundColor:
                                pikkXWhite,
                            disabledBackgroundColor:
                                pikkXBlack.withOpacity(0.45),
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: pikkXWhite,
                                  ),
                                )
                              : Text(
                                  address == null
                                      ? 'Save Address'
                                      : 'Update Address',
                                  style:
                                      const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
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
      },
    );
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<bool> _saveAddress({
    required bool isDefault,
  }) async {
    if (userId == null) {
      _showMessage(
        'Please sign in before saving an address.',
      );
      return false;
    }

    if (!_validateForm()) {
      return false;
    }

    if (mounted) {
      setState(() {
        isSaving = true;
      });
    }

    try {
      final batch = _firestore.batch();

      // Only one default address per user.
      if (isDefault) {
        final existing =
            await addressesRef.get();

        for (final doc in existing.docs) {
          if (doc.id != editingAddressId &&
              doc.data()['isDefault'] == true) {
            batch.update(
              doc.reference,
              {
                'isDefault': false,
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }
        }
      }

      final addressData =
          <String, dynamic>{
        'userId': userId,
        'fullName':
            _fullNameController.text.trim(),
        'phone':
            _phoneController.text.trim(),
        'addressLine':
            _addressController.text.trim(),
        'city':
            _cityController.text.trim(),
        'state':
            _stateController.text.trim(),
        'country':
            _countryController.text.trim(),
        'isDefault': isDefault,

        // Reserved for future map/location integration.
        'latitude': null,
        'longitude': null,

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      if (editingAddressId == null) {
        final newAddress =
            addressesRef.doc();

        addressData['addressId'] =
            newAddress.id;

        addressData['createdAt'] =
            FieldValue.serverTimestamp();

        batch.set(
          newAddress,
          addressData,
        );
      } else {
        final existingAddress =
            addressesRef.doc(
          editingAddressId,
        );

        batch.update(
          existingAddress,
          addressData,
        );
      }

      await batch.commit();

      await _loadAddresses();

      if (!mounted) return false;

      _showMessage(
        editingAddressId == null
            ? 'Address saved successfully.'
            : 'Address updated successfully.',
      );

      _clearForm();

      return true;
    } catch (e) {
      debugPrint(
        'Save address error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to save the address. Please try again.',
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE ADDRESS
  // ============================================================

  Future<void> _deleteAddress(
    String addressId,
  ) async {
    if (userId == null) return;

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: pikkXWhite,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete address?',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This saved delivery address will be removed.',
            style: TextStyle(
              color: muted,
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
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await addressesRef
          .doc(addressId)
          .delete();

      await _loadAddresses();

      if (mounted) {
        _showMessage(
          'Address deleted.',
        );
      }
    } catch (e) {
      debugPrint(
        'Delete address error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to delete the address.',
        );
      }
    }
  }

  // ============================================================
  // SET DEFAULT
  // ============================================================

  Future<void> _setDefaultAddress(
    String addressId,
  ) async {
    if (userId == null) return;

    try {
      final snapshot =
          await addressesRef.get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'isDefault':
                doc.id == addressId,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      await _loadAddresses();

      if (mounted) {
        _showMessage(
          'Default address updated.',
        );
      }
    } catch (e) {
      debugPrint(
        'Set default address error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to update the default address.',
        );
      }
    }
  }

  // ============================================================
  // SELECT ADDRESS FOR CHECKOUT
  // ============================================================

  void _selectAddress(
    Map<String, dynamic> address,
  ) {
    Navigator.pop(
      context,
      Map<String, dynamic>.from(address),
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateForm() {
    if (_fullNameController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Enter the recipient name.',
      );
      return false;
    }

    if (_phoneController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Enter a phone number.',
      );
      return false;
    }

    if (_addressController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Enter the house/street address.',
      );
      return false;
    }

    if (_cityController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Enter the city.',
      );
      return false;
    }

    if (_stateController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Enter the state.',
      );
      return false;
    }

    if (_countryController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'Enter the country.',
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void _clearForm() {
    editingAddressId = null;

    _fullNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();

    _countryController.text = 'Nigeria';
  }

  // ============================================================
  // FORM FIELD
  // ============================================================

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: pikkXBlack,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: pikkXNavy,
        ),
        filled: true,
        fillColor:
            pikkXWhite.withOpacity(0.72),
        labelStyle: const TextStyle(
          color: muted,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA0A3A7),
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: BorderSide(
            color:
                pikkXBlack.withOpacity(0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: BorderSide(
            color:
                pikkXBlack.withOpacity(0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: pikkXNavy,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _buildAddressCard(
    Map<String, dynamic> address,
  ) {
    final isDefault =
        address['isDefault'] == true;

    return _glassContainer(
      radius: 24,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(24),
        onTap: () {
          _selectAddress(address);
        },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: pikkXNavy,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: pikkXWhite,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address['fullName']
                                    ?.toString() ??
                                'Delivery Address',
                            style:
                                const TextStyle(
                              color: pikkXBlack,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),

                        if (isDefault)
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color: pikkXNavy,
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: pikkXWhite,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _formatAddress(address),
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    if (address['phone'] != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 5,
                        ),
                        child: Text(
                          address['phone']
                              .toString(),
                          style:
                              const TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _smallAction(
                          icon:
                              Icons.edit_outlined,
                          label: 'Edit',
                          onTap: () {
                            _openAddressForm(
                              address: address,
                            );
                          },
                        ),
                        _smallAction(
                          icon:
                              Icons.delete_outline,
                          label: 'Delete',
                          danger: true,
                          onTap: () {
                            _deleteAddress(
                              address['id']
                                  .toString(),
                            );
                          },
                        ),
                        if (!isDefault)
                          _smallAction(
                            icon: Icons
                                .check_circle_outline,
                            label: 'Set default',
                            onTap: () {
                              _setDefaultAddress(
                                address['id']
                                    .toString(),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAddress(
    Map<String, dynamic> address,
  ) {
    final parts = [
      address['addressLine'],
      address['city'],
      address['state'],
      address['country'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .map(
          (value) => value.toString().trim(),
        )
        .toList();

    return parts.isEmpty
        ? 'No address information'
        : parts.join(', ');
  }

  // ============================================================
  // SMALL ACTION
  // ============================================================

  Widget _smallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(11),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: pikkXWhite.withOpacity(0.68),
          borderRadius:
              BorderRadius.circular(11),
          border: Border.all(
            color:
                pikkXBlack.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  danger ? Colors.red : pikkXNavy,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    danger ? Colors.red : muted,
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(26),
        child: _glassContainer(
          radius: 28,
          child: Padding(
            padding:
                const EdgeInsets.all(28),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: pikkXNavy,
                    borderRadius:
                        BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 38,
                    color: pikkXWhite,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'No saved addresses',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Add your real delivery address so your orders can be delivered to you.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        _openAddressForm,
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                    label: const Text(
                      'Add Address',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
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
                                17),
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
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor: pikkXBlack,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
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
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Delivery Address',
          style: TextStyle(
            color: pikkXBlack,
            fontSize: 21,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: pikkXBlack,
        ),
      ),

      floatingActionButton:
          addresses.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed:
                      _openAddressForm,
                  backgroundColor:
                      pikkXBlack,
                  elevation: 8,
                  child: const Icon(
                    Icons.add_rounded,
                    color: pikkXWhite,
                  ),
                ),

      body: Stack(
        children: [
          // Subtle navy glow.
          Positioned(
            top: -90,
            right: -80,
            child: _glow(
              pikkXNavy,
              230,
              0.055,
            ),
          ),

          Positioned(
            bottom: -100,
            left: -90,
            child: _glow(
              pikkXNavy,
              250,
              0.035,
            ),
          ),

          isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: pikkXNavy,
                  ),
                )
              : addresses.isEmpty
                  ? _buildEmptyState()
                  : SafeArea(
                      child:
                          ListView.separated(
                        physics:
                            const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          8,
                          16,
                          100,
                        ),
                        itemCount:
                            addresses.length,
                        separatorBuilder:
                            (context, index) =>
                                const SizedBox(
                          height: 12,
                        ),
                        itemBuilder:
                            (context, index) {
                          return _buildAddressCard(
                            addresses[index],
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  // ============================================================
  // SOFT GLOW
  // ============================================================

  Widget _glow(
    Color color,
    double size,
    double opacity,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            color.withOpacity(opacity),
      ),
    );
  }

  // ============================================================
  // pikkX GLASS
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    double radius = 24,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          decoration: BoxDecoration(
            color:
                pikkXWhite.withOpacity(0.68),
            borderRadius:
                BorderRadius.circular(radius),
            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.92),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.055),
                blurRadius: 25,
                offset:
                    const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}