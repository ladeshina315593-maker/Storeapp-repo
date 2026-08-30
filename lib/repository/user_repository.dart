import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase user repository for Grape Go.
///
/// Responsibilities:
/// - Firebase Authentication
/// - Email/password authentication
/// - Phone authentication + OTP
/// - Google sign-in
/// - Facebook sign-in
/// - Apple sign-in
/// - Firestore user profiles
/// - Profile updates
/// - Logout
/// - Current-user access
class UserRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // COLLECTIONS
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ---------------------------------------------------------------------------
  // CURRENT USER
  // ---------------------------------------------------------------------------

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // EMAIL + PASSWORD
  // ---------------------------------------------------------------------------

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Unable to create the account.',
      );
    }

    await user.updateDisplayName(name.trim());

    await _createOrUpdateUserDocument(
      user: user,
      name: name,
    );

    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _createOrUpdateUserDocument(user: user);
    }

    return credential;
  }

  // ---------------------------------------------------------------------------
  // PHONE + OTP
  // ---------------------------------------------------------------------------

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    void Function(FirebaseAuthException error)? onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),

      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (e) {
          if (kDebugMode) {
            print('Automatic phone verification failed: $e');
          }
        }
      },

      verificationFailed: (FirebaseAuthException error) {
        if (onError != null) {
          onError(error);
        } else {
          throw error;
        }
      },

      codeSent: (
        String verificationId,
        int? resendToken,
      ) {
        onCodeSent(verificationId);
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );

    final result = await _auth.signInWithCredential(credential);

    final user = result.user;

    if (user != null) {
      await _createOrUpdateUserDocument(user: user);
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // GOOGLE
  // ---------------------------------------------------------------------------

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    final GoogleSignInAccount? googleUser =
        await googleSignIn.authenticate();

    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: (await googleUser.authorizationClient.authorizationForScopes(['email']))?.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);

    final user = result.user;

    if (user != null) {
      await _createOrUpdateUserDocument(user: user);
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // FACEBOOK
  // ---------------------------------------------------------------------------

  Future<UserCredential?> signInWithFacebook() async {
    final LoginResult result =
        await FacebookAuth.instance.login();

    if (result.status != LoginStatus.success) {
      return null;
    }

    final accessToken = result.accessToken;

    if (accessToken == null) {
      throw FirebaseAuthException(
        code: 'facebook-token-missing',
        message: 'Facebook authentication token was not received.',
      );
    }

    final credential =
        FacebookAuthProvider.credential(accessToken.tokenString);

    final userCredential =
        await _auth.signInWithCredential(credential);

    final user = userCredential.user;

    if (user != null) {
      await _createOrUpdateUserDocument(user: user);
    }

    return userCredential;
  }

  // ---------------------------------------------------------------------------
  // APPLE
  // ---------------------------------------------------------------------------

  Future<UserCredential?> signInWithApple() async {
    final bool available =
        await SignInWithApple.isAvailable();

    if (!available) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-unavailable',
        message: 'Apple Sign-In is not available on this device.',
      );
    }

    final appleCredential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential =
        OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final result =
        await _auth.signInWithCredential(oauthCredential);

    final user = result.user;

    if (user != null) {
      String? name;

      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;

      if (givenName != null || familyName != null) {
        name = [
          if (givenName != null) givenName,
          if (familyName != null) familyName,
        ].join(' ');
      }

      await _createOrUpdateUserDocument(
        user: user,
        name: name,
      );
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // USER PROFILE
  // ---------------------------------------------------------------------------

  Future<void> createUserProfile({
    required String name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'You must be logged in to create a profile.',
      );
    }

    await _usersCollection.doc(user.uid).set(
      {
        'uid': user.uid,
        'name': name.trim(),
        'email': email ?? user.email,
        'phoneNumber': phoneNumber ?? user.phoneNumber,
        'photoUrl': photoUrl ?? user.photoURL,
        'provider': _getProvider(user),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUserId;

    if (uid == null) {
      return null;
    }

    final document =
        await _usersCollection.doc(uid).get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream() {
    final uid = currentUserId;

    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No authenticated user exists.',
      );
    }

    return _usersCollection.doc(uid).snapshots();
  }

  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'You must be logged in.',
      );
    }

    final Map<String, dynamic> data = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      data['name'] = name.trim();
      await user.updateDisplayName(name.trim());
    }

    if (phoneNumber != null) {
      data['phoneNumber'] = phoneNumber.trim();
    }

    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
      await user.updatePhotoURL(photoUrl);
    }

    await _usersCollection
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // PASSWORD
  // ---------------------------------------------------------------------------

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> updatePassword({
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'You must be logged in.',
      );
    }

    await user.updatePassword(newPassword);
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    await GoogleSignIn.instance.signOut();

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Facebook may not have an active session.
    }

    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // ACCOUNT DELETION
  // ---------------------------------------------------------------------------

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No authenticated user exists.',
      );
    }

    final uid = user.uid;

    await _usersCollection.doc(uid).delete();

    await user.delete();
  }

  // ---------------------------------------------------------------------------
  // PRIVATE FIRESTORE USER CREATION
  // ---------------------------------------------------------------------------

  Future<void> _createOrUpdateUserDocument({
    required User user,
    String? name,
  }) async {
    final document =
        await _usersCollection.doc(user.uid).get();

    final existingData = document.data();

    final displayName =
        name?.trim().isNotEmpty == true
            ? name!.trim()
            : user.displayName;

    final Map<String, dynamic> data = {
      'uid': user.uid,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'name': displayName,
      'photoUrl': user.photoURL,
      'provider': _getProvider(user),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!document.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    // Don't overwrite an existing profile name with null.
    if (displayName == null &&
        existingData?['name'] != null) {
      data.remove('name');
    }

    await _usersCollection.doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // AUTH PROVIDER
  // ---------------------------------------------------------------------------

  String _getProvider(User user) {
    if (user.providerData.isEmpty) {
      return 'unknown';
    }

    final providerId =
        user.providerData.first.providerId;

    switch (providerId) {
      case 'google.com':
        return 'google';

      case 'facebook.com':
        return 'facebook';

      case 'apple.com':
        return 'apple';

      case 'phone':
        return 'phone';

      case 'password':
        return 'email';

      default:
        return providerId;
    }
  }
}