import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register new user ──
  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
  }) async {
    UserCredential? cred;
    try {
      cred = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      await _db.collection('users').doc(cred.user!.uid).set({
        'email':     email,
        'fullName':  fullName,
        'phone':     phone,
        'address':   address,
        'role':      'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } on FirebaseException catch (e) {
      if (cred != null) try { await cred.user?.delete(); } catch (_) {}
      return 'Database error: ${e.message}';
    } catch (e) {
      if (cred != null) try { await cred.user?.delete(); } catch (_) {}
      return 'Error: $e';
    }
  }

  // ── Admin creates member account ──
  Future<Map<String, dynamic>> createMemberAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String shopId,
    required String shopName,
  }) async {
    UserCredential? memberCred;
    try {
      memberCred = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      final memberUid = memberCred.user!.uid;

      await _db.collection('users').doc(memberUid).set({
        'email':     email,
        'fullName':  fullName,
        'phone':     phone,
        'address':   address,
        'role':      'member',
        'shopId':    shopId,
        'shopName':  shopName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();
      return {'success': true, 'uid': memberUid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e)};
    } on FirebaseException catch (e) {
      if (memberCred != null) try { await memberCred.user?.delete(); } catch (_) {}
      return {'success': false, 'error': 'Database error: ${e.message}'};
    } catch (e) {
      if (memberCred != null) try { await memberCred.user?.delete(); } catch (_) {}
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // ── Login ──
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Step 1: sign in
      final cred = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      final uid = cred.user!.uid;

      // Step 2: fetch user doc to check for rejection only
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        await _auth.signOut();
        return {'error': 'User data not found. Please register again.'};
      }

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String? ?? 'user';

      if (role == 'rejected') {
        await _auth.signOut();
        return {'error': 'rejected'};
      }

      return {'role': role};
    } on FirebaseAuthException catch (e) {
      return {'error': _authError(e)};
    } on FirebaseException catch (e) {
      return {'error': 'Database error: ${e.message}'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  // ── Activate Admin ──
  Future<String?> activateAdmin({
    required String uid,
    required String shopId,
    required String shopName,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'role':     'admin',
        'shopId':   shopId,
        'shopName': shopName,
      });
      return null;
    } catch (e) {
      return 'Error activating admin: $e';
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This username is already registered.';
      case 'invalid-email':
        return 'Invalid username format.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this username.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Incorrect username or password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Something went wrong. (${e.code})';
    }
  }
}