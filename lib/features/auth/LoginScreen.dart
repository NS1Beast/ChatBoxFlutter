// ignore_file: file_names
import 'package:flutter/material.dart';
import '../chat/screens/DashboardScreen.dart';
import 'AuthController.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _controller = AuthController();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  final _regEmailCtrl = TextEditingController();
  final _regOtpCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();

  final _forgotEmailCtrl = TextEditingController();
  final _forgotOtpCtrl = TextEditingController();
  final _forgotPassCtrl = TextEditingController();
  final _forgotConfirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    _regEmailCtrl.dispose(); _regOtpCtrl.dispose(); _regNameCtrl.dispose(); _regPassCtrl.dispose(); _regConfirmPassCtrl.dispose();
    _forgotEmailCtrl.dispose(); _forgotOtpCtrl.dispose(); _forgotPassCtrl.dispose(); _forgotConfirmPassCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
  }

  // --- HÀM XỬ LÝ LOGIN ---
  void _handleLogin() async {
    bool success = await _controller.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else if (mounted) {
       _showError('Đăng nhập thất bại. Kiểm tra lại Email/Mật khẩu!');
    }
  }

  void _handleGoogleAuth() async {
    bool success = await _controller.loginWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else if (mounted) {
      _showError('Đăng nhập Google thất bại hoặc đã bị hủy!');
    }
  }

  // --- HÀM XỬ LÝ ĐĂNG KÝ ---
  void _submitRegStep1() async {
    String? err = await _controller.checkEmailAndSendOTP(_regEmailCtrl.text.trim());
    if (err != null) _showError(err);
  }
  void _submitRegStep2() async {
    String? err = await _controller.verifyOTP(_regOtpCtrl.text.trim());
    if (err != null) _showError(err);
  }
  void _submitRegStep3() async {
    String name = _regNameCtrl.text.trim();
    String pass = _regPassCtrl.text;
    String confirmPass = _regConfirmPassCtrl.text;

    if (_controller.validateName(name) != null) { _showError(_controller.validateName(name)!); return; }
    if (_controller.validatePassword(pass) != null) { _showError(_controller.validatePassword(pass)!); return; }
    if (pass != confirmPass) { _showError("Xác nhận mật khẩu không khớp!"); return; }

    String? finalErr = await _controller.completeRegistration(name, pass);
    if (finalErr != null) { _showError(finalErr); } 
    else {
      _controller.switchForm(AuthFormType.login);
      _showSuccess('Tạo tài khoản thành công! Hãy đăng nhập.');
      _regEmailCtrl.clear(); _regOtpCtrl.clear(); _regNameCtrl.clear(); _regPassCtrl.clear(); _regConfirmPassCtrl.clear();
    }
  }

  // --- HÀM XỬ LÝ QUÊN MẬT KHẨU ---
  void _submitForgotStep1() async {
    String? err = await _controller.requestForgotPasswordOTP(_forgotEmailCtrl.text.trim());
    if (err != null) _showError(err);
  }
  void _submitForgotStep2() async {
    String? err = await _controller.verifyForgotOTP(_forgotOtpCtrl.text.trim());
    if (err != null) _showError(err);
  }
  void _submitForgotStep3() async {
    String pass = _forgotPassCtrl.text;
    String confirmPass = _forgotConfirmPassCtrl.text;

    if (_controller.validatePassword(pass) != null) { _showError(_controller.validatePassword(pass)!); return; }
    if (pass != confirmPass) { _showError("Xác nhận mật khẩu không khớp!"); return; }

    String? finalErr = await _controller.updateNewPassword(pass);
    if (finalErr != null) { _showError(finalErr); } 
    else {
      _controller.switchForm(AuthFormType.login);
      _showSuccess('Khôi phục mật khẩu thành công! Hãy đăng nhập bằng mật khẩu mới.');
      _forgotEmailCtrl.clear(); _forgotOtpCtrl.clear(); _forgotPassCtrl.clear(); _forgotConfirmPassCtrl.clear();
    }
  }

  // --- UI COMPONENTS ---
  Widget _buildTextField({required String label, required IconData icon, bool isPassword = false, bool? isPasswordVisible, VoidCallback? onVisibilityToggle, TextEditingController? controller, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), 
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !(isPasswordVisible ?? false),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          suffixIcon: isPassword
              ? IconButton(icon: Icon((isPasswordVisible ?? false) ? Icons.visibility_off : Icons.visibility), color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), onPressed: onVisibilityToggle)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, 
      children: [
        const SizedBox(height: 24),
        Row(children: [ Expanded(child: Divider(color: textColor.withValues(alpha: 0.2))), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('HOẶC', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: Divider(color: textColor.withValues(alpha: 0.2))) ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _controller.isLoading ? null : _handleGoogleAuth,
            icon: _controller.isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                : const Icon(Icons.g_mobiledata_rounded, size: 32, color: Colors.redAccent),
            label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Tiếp tục với Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor, padding: const EdgeInsets.symmetric(vertical: 18), 
              side: BorderSide(color: textColor.withValues(alpha: 0.25), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
          ),
        ),
      ],
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
              if (!isDesktop) ...[Icon(Icons.forum_rounded, size: 80, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 32)],
              Text('Chào mừng trở lại! 👋', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
              const SizedBox(height: 12),
              Text('Vui lòng đăng nhập tài khoản của bạn', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
              const SizedBox(height: 48),
              
              _buildTextField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined),
              _buildTextField(controller: _passCtrl, label: 'Mật khẩu', icon: Icons.lock_outline, isPassword: true, isPasswordVisible: _controller.isLoginPassVisible, onVisibilityToggle: _controller.toggleLoginPassVisibility),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => _controller.switchForm(AuthFormType.forgotPassword), child: Text('Quên mật khẩu?', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary))),
              ),
              const SizedBox(height: 24),
              
              FilledButton(
                onPressed: _controller.isLoading ? null : _handleLogin,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                child: _controller.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              
              _buildSocialLoginSection(textColor),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chưa có tài khoản?', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 15)),
                  TextButton(
                    onPressed: () {
                      _emailCtrl.clear(); _passCtrl.clear();
                      _controller.switchForm(AuthFormType.register);
                    }, 
                    child: Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary))
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
              Text(
                _controller.registerStep == 1 ? 'Bước 1: Cung cấp Email' : _controller.registerStep == 2 ? 'Bước 2: Xác minh Email' : 'Bước 3: Hoàn thiện hồ sơ', 
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 40),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation), child: child)),
                child: KeyedSubtree(
                  key: ValueKey<int>(_controller.registerStep),
                  child: Column(
                    children: [
                      // --- BƯỚC 1 ---
                      if (_controller.registerStep == 1) ...[
                        _buildTextField(controller: _regEmailCtrl, label: 'Email đăng ký', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _controller.isLoading ? null : _submitRegStep1,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _controller.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('GỬI MÃ OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],

                      // --- BƯỚC 2 ---
                      if (_controller.registerStep == 2) ...[
                        Text('Mã 6 số đã được gửi tới:\n${_controller.regEmail}', textAlign: TextAlign.center, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15)),
                        const SizedBox(height: 24),
                        _buildTextField(controller: _regOtpCtrl, label: 'Mã OTP (6 số)', icon: Icons.message_rounded, keyboardType: TextInputType.number),
                        Text('Hết hạn sau: ${_controller.otpTimerDisplay}', style: TextStyle(color: _controller.otpTimeLeft <= 30 ? Colors.red : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: (_controller.otpTimeLeft > 0 && !_controller.isLoading) ? _submitRegStep2 : null,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _controller.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('XÁC NHẬN MÃ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],

                      // --- BƯỚC 3 ---
                      if (_controller.registerStep == 3) ...[
                        _buildTextField(controller: _regNameCtrl, label: 'Tên hiển thị (Tên thật)', icon: Icons.person_outline),
                        _buildTextField(controller: _regPassCtrl, label: 'Mật khẩu', icon: Icons.lock_outline, isPassword: true, isPasswordVisible: _controller.isRegPassVisible, onVisibilityToggle: _controller.toggleRegPassVisibility),
                        _buildTextField(controller: _regConfirmPassCtrl, label: 'Xác nhận mật khẩu', icon: Icons.lock_reset_outlined, isPassword: true, isPasswordVisible: _controller.isRegConfirmPassVisible, onVisibilityToggle: _controller.toggleRegConfirmPassVisibility),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _controller.isLoading ? null : _submitRegStep3,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _controller.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('HOÀN TẤT ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              if (_controller.registerStep == 1) _buildSocialLoginSection(textColor),

              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  // 🎯 ĐÃ GỌI HÀM CỦA CONTROLLER CHUẨN XÁC, KHÔNG CÒN LỖI ĐỎ
                  onPressed: () => _controller.backRegisterStep(),
                  child: Text(_controller.registerStep > 1 ? '← Quay lại bước trước' : '← Quay lại Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
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
              Text(
                _controller.forgotStep == 1 ? 'Bước 1: Khai báo Email' : _controller.forgotStep == 2 ? 'Bước 2: Xác minh Email' : 'Bước 3: Đặt mật khẩu mới', 
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 40),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation), child: child)),
                child: KeyedSubtree(
                  key: ValueKey<int>(_controller.forgotStep),
                  child: Column(
                    children: [
                      // --- BƯỚC 1 ---
                      if (_controller.forgotStep == 1) ...[
                        _buildTextField(controller: _forgotEmailCtrl, label: 'Email đã đăng ký', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _controller.isLoading ? null : _submitForgotStep1,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _controller.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('GỬI MÃ KHÔI PHỤC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],

                      // --- BƯỚC 2 ---
                      if (_controller.forgotStep == 2) ...[
                        Text('Mã 6 số đã được gửi tới:\n${_controller.forgotEmail}', textAlign: TextAlign.center, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15)),
                        const SizedBox(height: 24),
                        _buildTextField(controller: _forgotOtpCtrl, label: 'Mã OTP (6 số)', icon: Icons.message_rounded, keyboardType: TextInputType.number),
                        Text('Hết hạn sau: ${_controller.forgotOtpTimerDisplay}', style: TextStyle(color: _controller.forgotOtpTimeLeft <= 30 ? Colors.red : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: (_controller.forgotOtpTimeLeft > 0 && !_controller.isLoading) ? _submitForgotStep2 : null,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _controller.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('XÁC NHẬN MÃ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],

                      // --- BƯỚC 3 ---
                      if (_controller.forgotStep == 3) ...[
                        _buildTextField(controller: _forgotPassCtrl, label: 'Mật khẩu mới', icon: Icons.lock_outline, isPassword: true, isPasswordVisible: _controller.isForgotPassVisible, onVisibilityToggle: _controller.toggleForgotPassVisibility),
                        _buildTextField(controller: _forgotConfirmPassCtrl, label: 'Xác nhận mật khẩu mới', icon: Icons.lock_reset_outlined, isPassword: true, isPasswordVisible: _controller.isForgotConfirmPassVisible, onVisibilityToggle: _controller.toggleForgotConfirmPassVisibility),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _controller.isLoading ? null : _submitForgotStep3,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _controller.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ĐỔI MẬT KHẨU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  // 🎯 ĐÃ GỌI HÀM CỦA CONTROLLER CHUẨN XÁC, KHÔNG CÒN LỖI ĐỎ
                  onPressed: () => _controller.backForgotStep(),
                  child: Text(_controller.forgotStep > 1 ? '← Quay lại bước trước' : '← Quay lại Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    const duration = Duration(milliseconds: 1200); 
    const curve = Curves.fastEaseInToSlowEaseOut;
    final double halfWidth = size.width / 2;
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
              Positioned(top: 0, bottom: 0, left: 0, width: halfWidth, child: Container(color: surfaceColor, child: _buildLoginForm(isDesktop, textColor))),
              Positioned(
                top: 0, bottom: 0, left: halfWidth, width: halfWidth,
                child: AnimatedOpacity(duration: const Duration(milliseconds: 400), opacity: isRegister ? 1.0 : 0.0, child: IgnorePointer(ignoring: !isRegister, child: Container(color: surfaceColor, child: _buildRegisterForm(isDesktop, textColor)))),
              ),
              Positioned(
                top: 0, bottom: 0, left: halfWidth, width: halfWidth,
                child: AnimatedOpacity(duration: const Duration(milliseconds: 400), opacity: isForgot ? 1.0 : 0.0, child: IgnorePointer(ignoring: !isForgot, child: Container(color: surfaceColor, child: _buildForgotPasswordForm(isDesktop, textColor)))),
              ),
              AnimatedPositioned(
                duration: duration, curve: curve, top: 0, bottom: 0, left: isLogin ? halfWidth : 0, width: halfWidth,
                child: AnimatedContainer(
                  duration: duration, curve: curve,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary, 
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, 0))],
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(isLogin ? 80 : 0), bottomLeft: Radius.circular(isLogin ? 80 : 0), topRight: Radius.circular(isLogin ? 0 : 80), bottomRight: Radius.circular(isLogin ? 0 : 80)),
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
                child: Container(key: ValueKey(_controller.currentForm), color: surfaceColor, child: isLogin ? _buildLoginForm(isDesktop, textColor) : isRegister ? _buildRegisterForm(isDesktop, textColor) : _buildForgotPasswordForm(isDesktop, textColor)),
              ),
          ),
        );
      }
    );
  }
}