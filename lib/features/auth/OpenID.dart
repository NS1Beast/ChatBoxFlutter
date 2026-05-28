import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class OpenIDService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  bool get _isDesktop {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) return;

    await _googleSignIn.initialize(
      serverClientId:
          '788545360820-4pssp1irp32bb28v1h2ig05r58632bku.apps.googleusercontent.com',
    );

    _isGoogleInitialized = true;
  }

  // ==========================================
  // 1. ĐĂNG NHẬP GOOGLE
  // ==========================================
  Future<String?> signInWithGoogle() async {
    if (_isDesktop) {
      return _handleDesktopOAuth('google');
    }

    try {
      await _ensureGoogleInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint('Nền tảng này không hỗ trợ GoogleSignIn.authenticate()');
        return null;
      }

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('Google Login Success: ${googleUser.email}');

      return googleAuth.idToken;
    } on GoogleSignInException catch (e) {
      debugPrint('Lỗi Google Sign-In: ${e.code.name} - ${e.description}');
      return null;
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      return null;
    }
  }

  // ==========================================
  // 2. DESKTOP OAUTH POPUP
  // ==========================================
  Future<String?> _handleDesktopOAuth(String provider) async {
    try {
      final String url = 'http://localhost:5034/api/auth/desktop-login/$provider';

      final String result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'prochat',
      );

      final Uri uri = Uri.parse(result);

      if (uri.scheme == 'prochat' && uri.host == 'login') {
        final String? token = uri.queryParameters['token'];

        if (token == null || token.isEmpty) {
          debugPrint('Không nhận được token từ deep link');
          return null;
        }

        return token;
      }

      debugPrint('Deep link không hợp lệ: $result');
      return null;
    } catch (e) {
      debugPrint('Lỗi đăng nhập desktop $provider: $e');
      return null;
    }
  }

  // ==========================================
  // 3. ĐĂNG XUẤT
  // ==========================================
  Future<void> signOut() async {
    if (_isDesktop) {
      return;
    }

    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Lỗi đăng xuất Google: $e');
    }
  }
}