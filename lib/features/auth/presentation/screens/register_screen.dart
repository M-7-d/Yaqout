import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

import '../../../../shared/widgets/curved_background.dart';
import '../../../../shared/widgets/decorative_points.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final String _role     = 'buyer';
  bool _obscure    = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role:     _role,
      fullName: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
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
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            onPressed: () => context.go('/auth/login'),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedBackground(
              height: 260,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogo(width: 250, color: Colors.white)
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 200.ms)
                          .scale(begin: const Offset(0.7, 0.7)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Card(
                elevation: 0,
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: AppColors.border, width: 1),
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
                              Text('Create Account',
                                      style: Theme.of(context).textTheme.displaySmall)
                                  .animate()
                                  .fadeIn(delay: 500.ms)
                                  .slideY(begin: 0.2),
                              const SizedBox(height: 8),
                              Text('Join Yakut and start exploring',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecond,
                                        fontSize: 15,
                                      )).animate().fadeIn(delay: 600.ms),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Full name
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: AppStrings.fullName,
                            labelStyle: const TextStyle(color: AppColors.textSecond),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.primaryLight.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border, width: 1),
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
                              v == null || v.isEmpty ? AppStrings.fieldRequired : null,
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 20),

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
                              borderSide: BorderSide(color: AppColors.border, width: 1),
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
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            labelStyle: const TextStyle(color: AppColors.textSecond),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined, color: AppColors.textSecond,),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            filled: true,
                            fillColor: AppColors.primaryLight.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border, width: 1),
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
                              v == null || v.length < 8 ? AppStrings.weakPassword : null,
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white))
                                : const Text(
                                    AppStrings.signUp,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ).animate().fadeIn(delay: 600.ms),
                        ),

                        const SizedBox(height: 28),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.hasAccount,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecond,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/auth/login'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: const Text(
                                  AppStrings.signIn,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const DecorativePoints(),
          ],
        ),
      ),
    );
  }
}
