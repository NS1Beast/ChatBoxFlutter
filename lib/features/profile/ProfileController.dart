// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; 

class ProfileController extends ChangeNotifier {
  static final ProfileController _instance = ProfileController._internal();
  factory ProfileController() => _instance;
  ProfileController._internal();

  // --- KẾT NỐI API BACKEND ---
  final String _usersApiUrl = 'http://localhost:5034/api/users';

  // --- STATE DỮ LIỆU ---
  String coverImageUrl = ''; 
  String avatarUrl = ''; 
  
  Uint8List? localAvatarBytes;
  Uint8List? localCoverBytes;

  String fullName = 'Đang tải...';
  String headline = 'Senior IT Student - AI Enthusiast 🚀';
  String bio = 'Đam mê C#, Python & Flutter | Thích Gym & Gaming';
  String email = 'Đang tải...';
  String location = 'Hồ Chí Minh, Việt Nam';
  String joinDate = 'Tháng 5, 2026';

  bool pushNotifications = true;
  bool privateProfile = false;
  String currentLanguage = 'Tiếng Việt';

  final ImagePicker _picker = ImagePicker();
  
  bool get _isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux);

  // ==========================================
  // HÀM TẢI THÔNG TIN CHUẨN TỪ DATABASE (TOKEN)
  // ==========================================
  Future<void> loadUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? localCustomName = prefs.getString('${userId}_name');

    // 1. Quét Database C# lấy thông tin mới nhất (Tên, Email, Ảnh)
    try {
      final response = await http.get(Uri.parse('$_usersApiUrl/profile/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        String dbName = data['fullname'] ?? "";
        String dbEmail = data['email'] ?? "";
        String dbAvatar = data['avatar'] ?? "";
        String dbCover = data['cover'] ?? "";

        // Cập nhật Tên
        if (dbName.isNotEmpty) {
          fullName = dbName;
          await prefs.setString('${userId}_name', dbName);
        } else if (localCustomName != null && localCustomName.isNotEmpty) {
          fullName = localCustomName;
        } else {
          fullName = "Người dùng";
        }

        // Cập nhật Email và URL Ảnh
        if (dbEmail.isNotEmpty) email = dbEmail;
        if (dbAvatar.isNotEmpty) avatarUrl = dbAvatar;
        if (dbCover.isNotEmpty) coverImageUrl = dbCover;
      }
    } catch (e) {
      debugPrint("Lỗi tải Profile từ DB: $e");
      if (localCustomName != null && localCustomName.isNotEmpty) fullName = localCustomName;
    }

    // 2. Load các thông tin phụ từ Local
    headline = prefs.getString('${userId}_headline') ?? headline;
    bio = prefs.getString('${userId}_bio') ?? bio;
    location = prefs.getString('${userId}_location') ?? location;

    String? avatarBase64 = prefs.getString('${userId}_avatarBytes');
    if (avatarBase64 != null) { localAvatarBytes = base64Decode(avatarBase64); }

    String? coverBase64 = prefs.getString('${userId}_coverBytes');
    if (coverBase64 != null) { localCoverBytes = base64Decode(coverBase64); }
    
    notifyListeners();
  }

  // ==========================================
  // HÀM CHỌN, CẮT & UPLOAD AVATAR LÊN DATABASE
  // ==========================================
  Future<void> pickAndCropAvatar(BuildContext context, String userId) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (!context.mounted) return;

    if (pickedFile != null) {
      if (_isDesktop) {
        localAvatarBytes = await pickedFile.readAsBytes();
      } else {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), 
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Căn chỉnh Avatar',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, 
              hideBottomControls: false, 
            ),
            IOSUiSettings(
              title: 'Căn chỉnh Avatar',
              cancelButtonTitle: 'Hủy',
              doneButtonTitle: 'Xong',
              aspectRatioLockEnabled: true,
            ),
            WebUiSettings(context: context),
          ],
        );
        if (croppedFile != null) { localAvatarBytes = await croppedFile.readAsBytes(); }
      }

      if (localAvatarBytes != null) {
        String base64Image = base64Encode(localAvatarBytes!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${userId}_avatarBytes', base64Image);
        notifyListeners(); 

        try {
          String formattedBase64 = "data:image/jpeg;base64,$base64Image";
          await http.post(
            Uri.parse('$_usersApiUrl/update-avatar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'imageBase64': formattedBase64
            }),
          );
          debugPrint("✅ Đã lưu Avatar lên Database thành công!");
        } catch (e) {
          debugPrint("❌ Lỗi khi upload Avatar lên DB: $e");
        }
      }
    }
  }

  // ==========================================
  // HÀM CHỌN, CẮT & UPLOAD ẢNH BÌA (COVER)
  // ==========================================
  Future<void> pickAndCropCover(BuildContext context, String userId) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (!context.mounted) return;

    if (pickedFile != null) {
      if (_isDesktop) {
        localCoverBytes = await pickedFile.readAsBytes();
      } else {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Căn chỉnh ảnh bìa',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Căn chỉnh ảnh bìa',
              cancelButtonTitle: 'Hủy',
              doneButtonTitle: 'Xong',
              aspectRatioLockEnabled: true,
            ),
            WebUiSettings(context: context),
          ],
        );
        if (croppedFile != null) { localCoverBytes = await croppedFile.readAsBytes(); }
      }

      // 🎯 NẾU CÓ ẢNH BÌA MỚI -> UPLOAD LÊN DATABASE
      if (localCoverBytes != null) {
        String base64Image = base64Encode(localCoverBytes!);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${userId}_coverBytes', base64Image);
        notifyListeners();
        
        try {
          String formattedBase64 = "data:image/jpeg;base64,$base64Image";
          await http.post(
            Uri.parse('$_usersApiUrl/update-cover'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'imageBase64': formattedBase64
            }),
          );
          debugPrint("✅ Đã lưu Ảnh bìa (Cover) lên Database thành công!");
        } catch (e) {
          debugPrint("❌ Lỗi khi upload Ảnh bìa lên DB: $e");
        }
      }
    }
  }

  // ==========================================
  // HÀM CHỈNH SỬA THÔNG TIN
  // ==========================================
  Future<void> updateProfileText({
    required String userId, required String newName, required String newHeadline, 
    required String newBio, required String newLocation
  }) async {
    fullName = newName; headline = newHeadline; bio = newBio; location = newLocation;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userId}_name', newName); 
    await prefs.setString('${userId}_headline', newHeadline);
    await prefs.setString('${userId}_bio', newBio);
    await prefs.setString('${userId}_location', newLocation);

    notifyListeners();
  }

  void shareProfile() { debugPrint('Chia sẻ hồ sơ của $fullName'); }
  void toggleNotifications(bool value) { pushNotifications = value; notifyListeners(); }
  void togglePrivacy(bool value) { privateProfile = value; notifyListeners(); }
  void logout() { debugPrint('Đăng xuất...'); }
}