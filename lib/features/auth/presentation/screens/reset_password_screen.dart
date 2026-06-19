import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/curved_background.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await ref.read(authNotifierProvider.notifier).updatePassword(_passCtrl.text);
      if (!mounted) return;
      
      context.go('/home');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedBackground(
              height: 220,
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text('New Password 🆕',
                            style: Theme.of(context).textTheme.displaySmall)
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideX(begin: -0.1),
                    const SizedBox(height: 8),
                    Text('Create a strong password for your account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecond,
                            )).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 32),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 8 ? AppStrings.weakPassword : null,
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (v) =>
                          v != _passCtrl.text ? 'Passwords do not match' : null,
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 32),

                    // Submit button
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Update Password'),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
