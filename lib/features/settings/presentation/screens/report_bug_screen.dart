import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({super.key});

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Using Supabase to save the bug report directly to the database.
      // You will need to create a 'bug_reports' table in your Supabase dashboard
      // with columns: id, title, description, created_at.
      // (Optional) You can set up a Supabase Database Webhook to send an email to you whenever a new row is added.
      
      await Supabase.instance.client.from('bug_reports').insert({
        'title': title,
        'description': desc,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bug report sent successfully! Thank you.')),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Report a Bug'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bug_report_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Found an issue?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Describe the bug below and it will be sent directly to our email support team.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecond,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),

            // Form
            const Text(
              'Bug Title',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. App crashes on login screen',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(),
            
            const SizedBox(height: 24),
            
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please provide as many details as possible, including steps to reproduce the issue...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideX(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Bug Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }
}
