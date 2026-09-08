import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseError(error));
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseError(error));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseError(error));
    }
  }

  /// Memastikan perubahan sensitif dilakukan oleh pemilik akun.
  Future<void> reauthenticateWithPassword(String currentPassword) async {
    try {
      final user = _requireUser();
      final email = user.email;

      if (email == null || email.trim().isEmpty) {
        throw Exception('Email akun tidak ditemukan');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseError(error));
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      final user = _requireUser();
      await user.updateDisplayName(name.trim());
      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseError(error));
    }
  }

  /// Firebase akan mengirim tautan verifikasi ke email baru.
  /// Email akun berubah setelah tautan tersebut dikonfirmasi pengguna.
  Future<void> requestEmailChange(String newEmail) async {
    try {
      final user = _requireUser();
      await user.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseError(error));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _requireUser();
      await user.updatePassword(newPassword);
      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseError(error));
    }
  }

  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User _requireUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Sesi login telah berakhir. Silakan login kembali.');
    }

    return user;
  }

  String _firebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email sudah digunakan oleh akun lain';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password baru minimal 6 karakter';
      case 'user-not-found':
        return 'Pengguna tidak ditemukan';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Password saat ini salah';
      case 'requires-recent-login':
        return 'Sesi keamanan telah berakhir. Masukkan password saat ini lalu coba kembali';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat nanti';
      case 'operation-not-allowed':
        return 'Perubahan akun ini belum diizinkan pada Firebase Authentication';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah';
      default:
        return error.message ?? 'Terjadi kesalahan pada akun';
    }
  }
}
