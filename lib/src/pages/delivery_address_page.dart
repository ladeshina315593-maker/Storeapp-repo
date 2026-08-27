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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // ============================================================
  // FIREBASE USER
  // ============================================================

  String? get userId => _auth.currentUser?.uid;

  // ============================================================
  // FIRESTORE PATH
  //
  // users/{userId}/addresses/{addressId}
  // ============================================================

  CollectionReference<Map<String, dynamic>> get addressesRef {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');
  }

  // ============================================================
  // INIT
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
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await addressesRef
          .orderBy('createdAt', descending: true)
          .get();

      final loadedAddresses = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          addresses = loadedAddresses;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load addresses error: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        _showMessage(
          'Unable to load your addresses.',
        );
      }
    }
  }

  // ============================================================
  // ADD / EDIT ADDRESS
  // ============================================================

  void _openAddressForm({
    Map<String, dynamic>? address,
  }) {
    editingAddressId = address?['id']?.toString();

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),
              child: _glassContainer(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address == null
                                  ? 'Add Address'
                                  : 'Edit Address',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.w800,
                                color:
                                    Color(0xFF1D2635),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color:
                                  Color(0xFF747F8F),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _formField(
                        controller:
                            _fullNameController,
                        label: 'Full Name',
                        hint: 'Enter recipient name',
                        icon:
                            Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller:
                            _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        icon:
                            Icons.phone_outlined,
                        keyboardType:
                            TextInputType.phone,
                      ),

                      const SizedBox(height: 14),

                      _formField(
                        controller:
                            _addressController,
                        label: 'Address',
                        hint:
                            'House number, street, area',
                        icon:
                            Icons.location_on_outlined,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 14),

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
                          const SizedBox(width: 12),
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

                      const SizedBox(height: 14),

                      _formField(
                        controller:
                            _countryController,
                        label: 'Country',
                        hint: 'Country',
                        icon:
                            Icons.public_outlined,
                      ),

                      const SizedBox(height: 10),

                      CheckboxListTile(
                        value: isDefault,
                        onChanged: (value) {
                          setModalState(() {
                            isDefault =
                                value ?? false;
                          });
                        },
                        contentPadding:
                            EdgeInsets.zero,
                        activeColor:
                            const Color(0xFFB98BEF),
                        title: const Text(
                          'Set as default address',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(0xFF1D2635),
                          ),
                        ),
                        controlAffinity:
                            ListTileControlAffinity
                                .leading,
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                                    19),
                            gradient:
                                const LinearGradient(
                              colors: [
                                Color(0xFFB98BEF),
                                Color(0xFF8F62D9),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color:
                                    Color(0x33B98BEF),
                                blurRadius: 18,
                                offset:
                                    Offset(0, 8),
                              ),
                            ],
                          ),
                          child:
                              ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final success =
                                        await _saveAddress(
                                      isDefault:
                                          isDefault,
                                    );

                                    if (success &&
                                        context
                                            .mounted) {
                                      Navigator.pop(
                                          context);
                                    }
                                  },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.transparent,
                              disabledBackgroundColor:
                                  Colors.transparent,
                              shadowColor:
                                  Colors.transparent,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            19),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : Text(
                                    address == null
                                        ? 'Save Address'
                                        : 'Update Address',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
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
  //
  // Creates:
  // users/{userId}/addresses/{addressId}
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

    setState(() {
      isSaving = true;
    });

    try {
      // If this address becomes default,
      // remove default from all other addresses first.
      if (isDefault) {
        final existing =
            await addressesRef.get();

        final batch = _firestore.batch();

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

        await batch.commit();
      }

      final addressData = {
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

        // Reserved for a future map/location feature.
        'latitude': null,
        'longitude': null,

        'isDefault': isDefault,

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      if (editingAddressId == null) {
        addressData['createdAt'] =
            FieldValue.serverTimestamp();

        await addressesRef.add(addressData);
      } else {
        await addressesRef
            .doc(editingAddressId)
            .update(addressData);
      }

      await _loadAddresses();

      if (mounted) {
        _showMessage(
          editingAddressId == null
              ? 'Address saved successfully.'
              : 'Address updated successfully.',
        );
      }

      _clearForm();

      return true;
    } catch (e) {
      debugPrint('Save address error: $e');

      if (mounted) {
        _showMessage(
          'Unable to save the address.',
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
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Address?',
          ),
          content: const Text(
            'This address will be removed from your saved addresses.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
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
          'Unable to update default address.',
        );
      }
    }
  }

  // ============================================================
  // SELECT ADDRESS
  //
  // Returns the address to CheckoutPage.
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
    if (_fullNameController.text.trim().isEmpty) {
      _showMessage('Enter the full name.');
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Enter the phone number.');
      return false;
    }

    if (_addressController.text.trim().isEmpty) {
      _showMessage('Enter the delivery address.');
      return false;
    }

    if (_cityController.text.trim().isEmpty) {
      _showMessage('Enter the city.');
      return false;
    }

    if (_stateController.text.trim().isEmpty) {
      _showMessage('Enter the state.');
      return false;
    }

    if (_countryController.text.trim().isEmpty) {
      _showMessage('Enter the country.');
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
        color: Color(0xFF1D2635),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF8F62D9),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.62),
        labelStyle: const TextStyle(
          color: Color(0xFF747F8F),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA1A3A6),
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFB98BEF),
            width: 1.3,
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
    final bool isDefault =
        address['isDefault'] == true;

    return _glassContainer(
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
                  color:
                      const Color(0xFFF8F5FF),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFB98BEF),
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
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(0xFF1D2635),
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
                              color:
                                  const Color(
                                      0xFFF8F5FF),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          10),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Color(
                                    0xFF8F62D9),
                                fontSize: 11,
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
                        color:
                            Color(0xFF797878),
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
                            color:
                                Color(0xFF747F8F),
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
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

                        const SizedBox(width: 8),

                        _smallAction(
                          icon:
                              Icons.delete_outline,
                          label: 'Delete',
                          onTap: () {
                            _deleteAddress(
                              address['id']
                                  .toString(),
                            );
                          },
                        ),

                        if (!isDefault) ...[
                          const SizedBox(width: 8),
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
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFFA1A3A6),
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
              value.toString()
                  .trim()
                  .isNotEmpty,
        )
        .map(
          (value) => value.toString(),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color:
              const Color(0xFFF8F5FF),
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  const Color(0xFF8F62D9),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color:
                    Color(0xFF747F8F),
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
            const EdgeInsets.all(30),
        child: _glassContainer(
          child: Padding(
            padding:
                const EdgeInsets.all(30),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  size: 58,
                  color:
                      Color(0xFFB98BEF),
                ),

                const SizedBox(height: 18),

                const Text(
                  'No saved addresses',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF1D2635),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Add a delivery address to make checkout faster.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Color(0xFF797878),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed:
                        _openAddressForm,
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                    label: const Text(
                      'Add Address',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xFFB98BEF),
                      foregroundColor:
                          Colors.white,
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
      backgroundColor:
          const Color(0xFFF8F5FF),

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Delivery Address',
          style: TextStyle(
            color:
                Color(0xFF1D2635),
            fontSize: 21,
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

      floatingActionButton:
          addresses.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed:
                      _openAddressForm,
                  backgroundColor:
                      const Color(
                          0xFFB98BEF),
                  elevation: 8,
                  child: const Icon(
                    Icons.add_rounded,
                    color:
                        Colors.white,
                  ),
                ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFB98BEF),
              ),
            )
          : addresses.isEmpty
              ? _buildEmptyState()
              : SafeArea(
                  child: ListView.separated(
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
    );
  }

  // ============================================================
  // GRAPEGO GLASS CONTAINER
  // ============================================================

  Widget _glassContainer({
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
            color: Colors.white
                .withOpacity(0.76),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white
                  .withOpacity(0.88),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.04),
                blurRadius: 18,
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
}