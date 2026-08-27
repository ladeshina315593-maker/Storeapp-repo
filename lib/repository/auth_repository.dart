import 'package:firebase_auth/firebase_auth.dart';

/// Handles all authentication operations for Grape Go.
///
/// Firebase Authentication is responsible for:
/// - Email/password
/// - Phone number + OTP
/// - Google
/// - Apple
/// - Facebook
/// - Sign out
/// - Current authentication state
///
/// UI pages should call this repository instead of
/// putting FirebaseAuth code directly inside widgets.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --------------------------------------------------
  // CURRENT USER
  // --------------------------------------------------

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // --------------------------------------------------
  // EMAIL / PASSWORD SIGN UP
  // --------------------------------------------------

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  // --------------------------------------------------
  // EMAIL / PASSWORD LOGIN
  // --------------------------------------------------

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  // --------------------------------------------------
  // PHONE NUMBER
  // --------------------------------------------------

  /// Sends the Firebase OTP to the supplied phone number.
  ///
  /// The verificationId returned by Firebase must be saved
  /// by the phone/OTP screen and then passed to
  /// verifyPhoneOtp().
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId)
        onCodeSent,
    required void Function(FirebaseAuthException error)
        onVerificationFailed,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          // Android can sometimes verify automatically.
          //
          // We intentionally don't sign in silently here
          // because the UI flow should remain predictable.
        },

        verificationFailed:
            (FirebaseAuthException error) {
          onVerificationFailed(error);
        },

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          onCodeSent(verificationId);
        },

        codeAutoRetrievalTimeout:
            (String verificationId) {
          onCodeAutoRetrievalTimeout
              ?.call(verificationId);
        },
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw _handleFirebaseError(e);
      }

      throw 'Unable to send verification code.';
    }
  }

  // --------------------------------------------------
  // VERIFY PHONE OTP
  // --------------------------------------------------

  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (_) {
      throw 'Invalid verification code.';
    }
  }

  // --------------------------------------------------
  // GOOGLE
  // --------------------------------------------------

  Future<UserCredential> loginWithGoogle() async {
    try {
      /*
       * Google implementation will be connected here.
       *
       * Example architecture:
       *
       * final GoogleSignInAccount? googleUser =
       *     await GoogleSignIn().signIn();
       *
       * if (googleUser == null) {
       *   throw 'Google sign-in was cancelled.';
       * }
       *
       * final GoogleSignInAuthentication
       *     googleAuth =
       *     await googleUser.authentication;
       *
       * final credential =
       *     GoogleAuthProvider.credential(
       *       accessToken: googleAuth.accessToken,
       *       idToken: googleAuth.idToken,
       *     );
       *
       * return await _auth.signInWithCredential(
       *   credential,
       * );
       */

      throw 'Google sign-in is not configured yet.';
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw _handleFirebaseError(e);
      }

      rethrow;
    }
  }

  // --------------------------------------------------
  // APPLE
  // --------------------------------------------------

  Future<UserCredential> loginWithApple() async {
    try {
      /*
       * Apple implementation belongs here.
       *
       * Firebase provider:
       *
       * final provider =
       *     AppleAuthProvider();
       *
       * return await _auth.signInWithProvider(
       *     provider,
       * );
       *
       * The exact implementation depends on
       * the platforms you configure in Firebase.
       */

      throw 'Apple sign-in is not configured yet.';
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw _handleFirebaseError(e);
      }

      rethrow;
    }
  }

  // --------------------------------------------------
  // FACEBOOK
  // --------------------------------------------------

  Future<UserCredential> loginWithFacebook() async {
    try {
      /*
       * Facebook implementation belongs here.
       *
       * After Facebook Login returns an access token:
       *
       * final credential =
       *     FacebookAuthProvider.credential(
       *       accessToken,
       *     );
       *
       * return await _auth.signInWithCredential(
       *     credential,
       * );
       *
       * Facebook Login must first be configured
       * in Firebase and the Facebook developer console.
       */

      throw 'Facebook sign-in is not configured yet.';
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw _handleFirebaseError(e);
      }

      rethrow;
    }
  }

  // --------------------------------------------------
  // PASSWORD RESET
  // --------------------------------------------------

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (_) {
      throw 'Unable to send password reset email.';
    }
  }

  // --------------------------------------------------
  // EMAIL VERIFICATION
  // --------------------------------------------------

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw 'No user is currently signed in.';
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      rethrow;
    }
  }

  // --------------------------------------------------
  // REFRESH USER
  // --------------------------------------------------

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  // --------------------------------------------------
  // LOG OUT
  // --------------------------------------------------

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (_) {
      throw 'Unable to log out. Please try again.';
    }
  }

  // --------------------------------------------------
  // DELETE ACCOUNT
  // --------------------------------------------------

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw 'No user is currently signed in.';
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (_) {
      throw 'Unable to delete account.';
    }
  }

  // --------------------------------------------------
  // FIREBASE ERROR HANDLING
  // --------------------------------------------------

  String _handleFirebaseError(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account was found with these details.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Please choose a stronger password.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'invalid-verification-code':
        return 'The OTP code is incorrect.';

      case 'invalid-verification-id':
        return 'The verification session has expired.';

      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';

      case 'credential-already-in-use':
        return 'This account is already connected to another user.';

      default:
        return error.message ??
            'Authentication failed. Please try again.';
    }
  }
}