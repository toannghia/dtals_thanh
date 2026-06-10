import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/storage/secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../data/auth_repository.dart';
import '../../../../core/widgets/app_toast.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);
      
      try {
        await AuthRepository().register({
          'username': _usernameController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'password': _passwordController.text,
        });

        if (_rememberMe) {
          await SecureStorage().saveCredentials(
            _usernameController.text.trim(),
            _passwordController.text,
          );
        } else {
          await SecureStorage().clearCredentials();
        }

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Đăng ký thành công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Tài khoản của bạn đã được tạo thành công.\n\nVui lòng kiểm tra hộp thư email và nhấn vào link kích hoạt để có thể đăng nhập vào hệ thống.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/login');
                  },
                  child: const Text('Về trang đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } on DioException catch (e) {
        String message = e.response?.data?['message']?.toString() ?? 'Đăng ký thất bại';
        if (mounted) {
          AppToast.show(context, message, type: AppToastType.error);
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, 'Đã xảy ra lỗi không mong muốn', type: AppToastType.error);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            bottom: size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Đăng ký tài khoản',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(labelText: 'Tên đăng nhập', prefixIcon: Icon(Icons.person_outline)),
                                textInputAction: TextInputAction.next,
                                validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.badge_outlined)),
                                textInputAction: TextInputAction.next,
                                validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                                textInputAction: TextInputAction.next,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  if (!val.contains('@')) return 'Email không hợp lệ';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Xác nhận mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleRegister(),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  if (val != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Nhớ tài khoản cho lần đăng nhập sau', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              PrimaryButton(
                                text: 'Đăng ký',
                                isLoading: _isLoading,
                                onPressed: _handleRegister,
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Đã có tài khoản?',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                  ),
                                  TextButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
