import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        print('User created successfully: ${user.uid}');
        return {'success': true, 'user': user};
      } else {
        print('User creation failed: No user returned');
        return {'success': false, 'error': 'User creation failed: No user returned'};
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak. Please use a stronger password.';
          break;
        default:
          errorMessage = 'Sign-up failed: ${e.message}';
      }
      print('FirebaseAuthException during sign-up: $errorMessage');
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('Unexpected error during sign-up: $e');
      User? user = _auth.currentUser;
      if (user != null && user.email == email) {
        print('User was created despite error: ${user.uid}');
        return {'success': true, 'user': user};
      }
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Log in with email and password
  Future<Map<String, dynamic>> logInWithEmail(String email, String password) async {
    try {
      print('Attempting to log in with email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('UserCredential obtained: ${userCredential.user?.uid}');
      User? user = userCredential.user;
      if (user != null) {
        print('User logged in successfully: ${user.uid}');
        return {'success': true, 'user': user};
      } else {
        print('Login failed: No user returned');
        return {'success': false, 'error': 'Login failed: No user returned'};
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      print('FirebaseAuthException during login: $errorMessage');
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('Unexpected error during login: $e');
      // Check if the user is logged in despite the error
      User? user = _auth.currentUser;
      if (user != null && user.email == email) {
        print('User was logged in despite error: ${user.uid}');
        return {'success': true, 'user': user};
      }
      // If the error is the PigeonUserDetails type cast issue, try waiting briefly and rechecking
      await Future.delayed(const Duration(milliseconds: 500));
      user = _auth.currentUser;
      if (user != null && user.email == email) {
        print('User was logged in after delay: ${user.uid}');
        return {'success': true, 'user': user};
      }
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google Sign-In canceled by user'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      print('Google Sign-In error: ${e.message}');
      return {'success': false, 'error': 'Google Sign-In failed: ${e.message}'};
    } catch (e) {
      print('Unexpected Google Sign-In error: $e');
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}