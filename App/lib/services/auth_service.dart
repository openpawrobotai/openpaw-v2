import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendOTPToEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (!userCredential.user!.emailVerified) {
          await userCredential.user?.sendEmailVerification();
        }
      } else {
        rethrow;
      }
    }
  }

  Future<bool> verifyEmail() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null && userCredential.user!.emailVerified) {
      await _saveUserToDatabase(userCredential.user!);
    }

    return userCredential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    
    if (userCredential.user != null) {
      await _saveUserToDatabase(userCredential.user!);
    }

    return userCredential;
  }

  Future<void> _saveUserToDatabase(User user) async {
    final userRef = _database.child('users').child(user.uid);
    await userRef.update({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'last_login': ServerValue.timestamp,
      'email_verified': user.emailVerified,
    });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }
}
