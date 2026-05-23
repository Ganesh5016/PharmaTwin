import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class AuthService {
  final ApiClient _apiClient;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '471111716211-jc9nt8pvdkpa8im3ao804fdtfuqjg1ne.apps.googleusercontent.com',
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Get Firebase ID token and exchange for JWT
    final idToken = await credential.user?.getIdToken();
    if (idToken != null) {
      await _exchangeFirebaseToken(idToken);
    }

    return credential;
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String name,
    String role,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    // Register with backend
    final idToken = await credential.user?.getIdToken();
    if (idToken != null) {
      await _apiClient.post(AppConstants.authRegister, data: {
        'firebase_uid': credential.user?.uid,
        'email': email,
        'name': name,
        'role': role,
        'id_token': idToken,
      });
      await _exchangeFirebaseToken(idToken);
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken != null) {
      await _exchangeFirebaseToken(idToken);
    }

    return userCredential;
  }

  Future<void> _exchangeFirebaseToken(String idToken) async {
    try {
      final response = await _apiClient.post(AppConstants.authLogin, data: {
        'id_token': idToken,
      });
      await _storage.write(
        key: AppConstants.kAccessToken,
        value: response.data['access_token'],
      );
      await _storage.write(
        key: AppConstants.kRefreshToken,
        value: response.data['refresh_token'],
      );
      await _storage.write(
        key: AppConstants.kUserRole,
        value: response.data['role'],
      );
    } catch (e) {
      // Store Firebase token as fallback
      await _storage.write(key: AppConstants.kAccessToken, value: idToken);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _storage.deleteAll();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.kUserRole);
  }
}
