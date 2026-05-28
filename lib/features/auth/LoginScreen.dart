import 'package:flutter/material.dart';
// Nhớ tạo file DashboardScreen trống nếu chưa có, hoặc comment dòng này lại để test
import '../chat/screens/DashboardScreen.dart'; 
import 'AuthController.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _controller = AuthController();

  // Hàm xử lý Đăng nhập truyền thống
  void _handleLogin() async {
    // Tạm thời gọi cứng để test, sau này ông gán TextEditingController vào đây nhé
    bool success = await _controller.login("1", "1");
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    }
  }

  // Hàm xử lý Đăng nhập Google
  void _handleGoogleAuth() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang kết nối Google...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2), 
      ),
    );
    
    // Gọi sang AuthController để mở trình duyệt
    bool success = await _controller.loginWithGoogle();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập Google thất bại hoặc đã bị hủy!'),
          backgroundColor: Colors.redAccent,
        )
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onVisibilityToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), 
      child: TextFormField(
        obscureText: isPassword && !(isPasswordVisible ?? false),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon((isPasswordVisible ?? false) ? Icons.visibility_off : Icons.visibility),
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  onPressed: onVisibilityToggle,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Ép kéo dãn toàn bộ phần tử
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: textColor.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('HOẶC', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: textColor.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: 24),
        
        // Bọc trong SizedBox vô cực để dài ngang mép nút Đăng nhập
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleGoogleAuth,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 32, color: Colors.redAccent),
            
            // Dùng FittedBox để chữ tự động co giãn không bao giờ bị tràn khung
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Tiếp tục với Google', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
            
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor, // Màu chữ và hiệu ứng gợn sóng
              padding: const EdgeInsets.symmetric(vertical: 18), // Chỉnh padding để cao bằng nút FilledButton
              side: BorderSide(color: textColor.withValues(alpha: 0.25), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    
    const duration = Duration(milliseconds: 1200); 
    const curve = Curves.fastEaseInToSlowEaseOut;

    final double fullWidth = size.width;
    final double halfWidth = fullWidth / 2;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        bool isLogin = _controller.currentForm == AuthFormType.login;
        bool isRegister = _controller.currentForm == AuthFormType.register;
        bool isForgot = _controller.currentForm == AuthFormType.forgotPassword;

        return Scaffold(
          backgroundColor: surfaceColor,
          body: isDesktop 
          ? Stack(
            children: [
              Positioned(
                top: 0, bottom: 0, left: 0, width: halfWidth,
                child: Container(color: surfaceColor, child: _buildLoginForm(isDesktop, textColor)),
              ),
              Positioned(
                top: 0, bottom: 0, left: halfWidth, width: halfWidth,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400), opacity: isRegister ? 1.0 : 0.0,
                  child: IgnorePointer(ignoring: !isRegister, child: Container(color: surfaceColor, child: _buildRegisterForm(isDesktop, textColor))),
                ),
              ),
              Positioned(
                top: 0, bottom: 0, left: halfWidth, width: halfWidth,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400), opacity: isForgot ? 1.0 : 0.0,
                  child: IgnorePointer(ignoring: !isForgot, child: Container(color: surfaceColor, child: _buildForgotPasswordForm(isDesktop, textColor))),
                ),
              ),
              AnimatedPositioned(
                duration: duration, curve: curve,
                top: 0, bottom: 0, left: isLogin ? halfWidth : 0, width: halfWidth,
                child: AnimatedContainer(
                  duration: duration, curve: curve,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary, 
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, 0))],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isLogin ? 80 : 0), bottomLeft: Radius.circular(isLogin ? 80 : 0),
                      topRight: Radius.circular(isLogin ? 0 : 80), bottomRight: Radius.circular(isLogin ? 0 : 80),
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.forum_rounded, size: 140, color: Colors.white),
                          const SizedBox(height: 32),
                          Text('Your chat companion,\nanytime, anywhere', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          const SizedBox(height: 20),
                          Text('Kết nối mọi lúc, mọi nơi\nAn toàn & Tốc độ', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white.withValues(alpha: 0.8), height: 1.6)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
          : SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  key: ValueKey(_controller.currentForm),
                  color: surfaceColor,
                  child: isLogin ? _buildLoginForm(isDesktop, textColor) : isRegister ? _buildRegisterForm(isDesktop, textColor) : _buildForgotPasswordForm(isDesktop, textColor),
                ),
              ),
          ),
        );
      }
    );
  }

  Widget _buildLoginForm(bool isDesktop, Color textColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
                Icon(Icons.forum_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 32),
              ],
              Text('Chào mừng trở lại! 👋', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
              const SizedBox(height: 12),
              Text('Vui lòng đăng nhập tài khoản của bạn', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
              const SizedBox(height: 48),
              
              _buildTextField(label: 'Email', icon: Icons.email_outlined),
              _buildTextField(
                label: 'Mật khẩu', icon: Icons.lock_outline, isPassword: true,
                isPasswordVisible: _controller.isLoginPassVisible, onVisibilityToggle: _controller.toggleLoginPassVisibility,
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _controller.switchForm(AuthFormType.forgotPassword),
                  child: Text('Quên mật khẩu?', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              const SizedBox(height: 24),
              
              FilledButton(
                onPressed: _handleLogin,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5, shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                child: const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              
              _buildSocialLoginSection(textColor),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chưa có tài khoản?', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 15)),
                  TextButton(
                    onPressed: () => _controller.switchForm(AuthFormType.register),
                    child: Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm(bool isDesktop, Color textColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tạo tài khoản mới ✨', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Text('Trải nghiệm nhắn tin tốc độ cao ngay hôm nay', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16)),
              const SizedBox(height: 40),
              
              _buildTextField(label: 'Họ và tên', icon: Icons.person_outline),
              _buildTextField(label: 'Email', icon: Icons.email_outlined),
              _buildTextField(
                label: 'Mật khẩu', icon: Icons.lock_outline, isPassword: true,
                isPasswordVisible: _controller.isRegPassVisible, onVisibilityToggle: _controller.toggleRegPassVisibility,
              ),
              _buildTextField(
                label: 'Xác nhận mật khẩu', icon: Icons.lock_reset_outlined, isPassword: true,
                isPasswordVisible: _controller.isRegConfirmPassVisible, onVisibilityToggle: _controller.toggleRegConfirmPassVisibility,
              ),
              
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  bool success = await _controller.register("name", "email", "pass");
                  if (success && mounted) {
                    _controller.switchForm(AuthFormType.login);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
                  }
                },
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              
              _buildSocialLoginSection(textColor),

              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => _controller.switchForm(AuthFormType.login),
                  child: Text('← Quay lại Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm(bool isDesktop, Color textColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Khôi phục mật khẩu 🔐', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Text('Nhập email của bạn, chúng tôi sẽ gửi liên kết đặt lại mật khẩu.', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16, height: 1.5)),
              const SizedBox(height: 40),
              
              _buildTextField(label: 'Email đã đăng ký', icon: Icons.email_outlined),
              
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  bool success = await _controller.resetPassword("email");
                  if (success && mounted) {
                    _controller.switchForm(AuthFormType.login);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi email khôi phục!')));
                  }
                },
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('GỬI LIÊN KẾT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => _controller.switchForm(AuthFormType.login),
                  child: Text('← Quay lại Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}