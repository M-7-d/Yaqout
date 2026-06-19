import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/curved_background.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();
    try {
      await ref.read(authNotifierProvider.notifier).sendPasswordReset(email);
      if (!mounted) return;
      
      context.go('/auth/forgot-password/verify?email=$email');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code sent to your email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedBackground(
              height: 240,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: const AppLogo(width: 200, color: Colors.white)
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Card(
                elevation: 0,
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text('Forgot Password 🔑',
                                      style: Theme.of(context).textTheme.displaySmall)
                                  .animate()
                                  .fadeIn(delay: 600.ms)
                                  .slideY(begin: 0.2),
                              const SizedBox(height: 8),
                              Text('Enter your email to receive a password reset code',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecond,
                                        fontSize: 15,
                                      )).animate().fadeIn(delay: 700.ms),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: AppStrings.email,
                            labelStyle: const TextStyle(color: AppColors.textSecond),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.primaryLight.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.border, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.error, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.error, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                          validator: (v) =>
                              v == null || !v.contains('@') ? AppStrings.invalidEmail : null,
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text(
                                    'Send Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ).animate().fadeIn(delay: 600.ms),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
