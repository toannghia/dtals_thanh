import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/storage/secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await SecureStorage().getCredentials();
    if (credentials['username'] != null && credentials['password'] != null) {
      if (mounted) {
        setState(() {
          _usernameController.text = credentials['username']!;
          _passwordController.text = credentials['password']!;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show error snackbar when errorMessage changes
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        AppToast.show(
          context,
          next.errorMessage!,
          type: AppToastType.error,
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Premium Background Gradient
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Header
                      const Icon(Icons.satellite_alt_rounded, size: 72, color: Colors.white),
                      const SizedBox(height: 24),
                      const Text(
                        'DTALS Mobile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hệ thống quản lý trạm CORS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Login Card
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
                              Text(
                                'Đăng nhập',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Tên đăng nhập',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập tên đăng nhập';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    // Make sure touch target is large enough
                                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
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
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Nhớ tài khoản và mật khẩu', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              PrimaryButton(
                                text: 'Đăng nhập',
                                isLoading: authState.status == AuthStatus.loading,
                                onPressed: _handleLogin,
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Chưa có tài khoản?',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/register'),
                                    child: const Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold)),
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

