import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/constants/firestore_paths.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../models/user_model.dart';

// ── Abstract contract ─────────────────────────────────────────────────────────

abstract class AuthRepository {
  /// The currently signed-in Firebase user, or null.
  User? get currentFirebaseUser;

  /// True if the current user signed in anonymously (guest).
  bool get isGuest;

  /// Emits raw Firebase [User] changes. Used by [AuthBloc] to react to
  /// sign-in / sign-out and trigger a [UserModel] fetch.
  Stream<User?> get authStateChanges;

  Future<Result<UserModel>> signInWithEmailAndPassword(
      String email, String password);

  Future<Result<UserModel>> createUserWithEmailAndPassword(
      String email, String password);

  Future<Result<UserModel>> signInWithGoogle();

  /// Anonymous Firebase sign-in. Creates a minimal Firestore user document so
  /// the guest can accumulate progress before upgrading to a real account.
  Future<Result<UserModel>> signInAsGuest();

  /// Best-effort sign-out. Returns [Err] only for unexpected failures.
  Future<Result<void>> signOut();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<UserModel?>> fetchCurrentUser();
}

// ── Firebase implementation ───────────────────────────────────────────────────

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  @override
  User? get currentFirebaseUser => _auth.currentUser;

  @override
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<Result<UserModel>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = await _fetchOrCreateUser(credential.user!);
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(e.message ?? 'Sign in failed.'));
    } catch (e) {
      return Err(UnknownFailure('$e'));
    }
  }

  @override
  Future<Result<UserModel>> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = await _fetchOrCreateUser(credential.user!);
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(e.message ?? 'Sign up failed.'));
    } catch (e) {
      return Err(UnknownFailure('$e'));
    }
  }

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Err(AuthFailure('Google sign-in cancelled.'));
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;
      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        // Guest upgrading to a real account — link the anonymous UID to the
        // Google credential so progress accumulated as a guest is preserved.
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // The Google account is already linked to another Firebase user;
            // sign in to that existing account instead.
            userCredential = await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = await _fetchOrCreateUser(userCredential.user!);
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(e.message ?? 'Google sign-in failed.'));
    } catch (e) {
      return Err(UnknownFailure('$e'));
    }
  }

  @override
  Future<Result<UserModel>> signInAsGuest() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final firebaseUser = userCredential.user!;
      final docRef = _firestore.doc(FirestorePaths.userDoc(firebaseUser.uid));
      final doc = await docRef.get();

      if (doc.exists) return Success(UserModel.fromFirestore(doc));

      final now = DateTime.now();
      final guestUser = UserModel(
        uid: firebaseUser.uid,
        displayName: 'Guest',
        createdAt: now,
        lastActiveAt: now,
      );
      await docRef.set(guestUser.toFirestore());
      return Success(guestUser);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(e.message ?? 'Guest sign-in failed.'));
    } catch (e) {
      return Err(UnknownFailure('$e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      return const Success(null);
    } catch (e) {
      return Err(UnknownFailure('Sign out failed: $e'));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(e.message ?? 'Password reset failed.'));
    } catch (e) {
      return Err(UnknownFailure('$e'));
    }
  }

  @override
  Future<Result<UserModel?>> fetchCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Success(null);
      final doc =
          await _firestore.doc(FirestorePaths.userDoc(user.uid)).get();
      if (!doc.exists) return const Success(null);
      return Success(UserModel.fromFirestore(doc));
    } catch (e) {
      return Err(ServerFailure('Failed to fetch user: $e'));
    }
  }

  Future<UserModel> _fetchOrCreateUser(User firebaseUser) async {
    final docRef = _firestore.doc(FirestorePaths.userDoc(firebaseUser.uid));
    final doc = await docRef.get();

    if (doc.exists) return UserModel.fromFirestore(doc);

    final now = DateTime.now();
    final newUser = UserModel(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? '',
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
      createdAt: now,
      lastActiveAt: now,
    );
    await docRef.set(newUser.toFirestore());
    return newUser;
  }
}
