import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/curved_background.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).verifyCode(
        widget.email,
        _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      
      context.go('/auth/forgot-password/reset');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code verified successfully')),
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
                    Text('Verify Code 🛡️',
                            style: Theme.of(context).textTheme.displaySmall)
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideX(begin: -0.1),
                    const SizedBox(height: 8),
                    Text('Enter the 6-digit code sent to ${widget.email}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecond,
                            )).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 32),

                    // Code
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                      decoration: const InputDecoration(
                        labelText: 'Reset Code',
                        hintText: '000000',
                        prefixIcon: Icon(Icons.security),
                      ),
                      validator: (v) =>
                          v == null || v.length != 6 ? 'Enter the 6-digit code' : null,
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Verify Code'),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 16),
                    
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : () async {
                          setState(() => _isLoading = true);
                          try {
                            await ref.read(authNotifierProvider.notifier).sendPasswordReset(widget.email);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New code sent')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        child: const Text('Resend Code'),
                      ),
                    ),
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
