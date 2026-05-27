import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

class OpenIDService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

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
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return await _handleDesktopOAuth('google');
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
          googleUser.authentication;

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
  // 2. ĐĂNG NHẬP FACEBOOK
  // ==========================================
  Future<String?> signInWithFacebook() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return await _handleDesktopOAuth('facebook');
    }

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        debugPrint('Facebook Login Success');
        return accessToken.tokenString;
      }

      debugPrint('Facebook Login failed: ${result.message}');
      return null;
    } catch (e) {
      debugPrint('Lỗi Exception Facebook: $e');
      return null;
    }
  }

  // ==========================================
  // 3. DESKTOP OAUTH
  // ==========================================
  Future<String?> _handleDesktopOAuth(String provider) async {
    final Completer<String?> completer = Completer<String?>();

    final Uri url = Uri.parse(
      'http://localhost:5000/api/auth/desktop-login/$provider',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Không thể mở trình duyệt');
      return null;
    }

    await _linkSubscription?.cancel();

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        if (uri.scheme == 'prochat' && uri.host == 'login') {
          final String? token = uri.queryParameters['token'];

          if (!completer.isCompleted) {
            completer.complete(token);
          }

          _linkSubscription?.cancel();
        }
      },
      onError: (err) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    Future.delayed(const Duration(minutes: 2), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        _linkSubscription?.cancel();
        debugPrint('Hết thời gian chờ đăng nhập Desktop');
      }
    });

    return completer.future;
  }

  // ==========================================
  // 4. ĐĂNG XUẤT
  // ==========================================
  Future<void> signOut() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }

    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Lỗi đăng xuất Google: $e');
    }

    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('Lỗi đăng xuất Facebook: $e');
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
  }
}