import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import 'auth_experience_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final AuthService _authService;

  bool _checking = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _timer;
  String? _message;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    try {
      final verified = await _authService.reloadAndCheckEmailVerified();
      if (!mounted) return;
      if (!verified) {
        setState(() {
          _message =
              'Verification is not complete yet. Open the email, verify, then try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;

    setState(() {
      _resending = true;
      _message = null;
    });

    try {
      await _authService.sendVerificationEmail();
      if (!mounted) return;
      setState(() {
        _message = 'A fresh verification email has been sent.';
        _cooldown = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_cooldown <= 1) {
          timer.cancel();
          setState(() => _cooldown = 0);
        } else {
          setState(() => _cooldown -= 1);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'We could not resend the verification email yet. Please try again shortly.';
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? 'your email address';

    return AuthExperienceShell(
      eyebrow: 'EMAIL VERIFICATION',
      title: 'One quick identity check.',
      subtitle:
          'Verification protects learner progress and keeps each study account tied to its owner.',
      child: AuthCard(
        title: 'Verify your email',
        subtitle:
            'We sent a secure verification link to $email. Open it, then return here.',
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security_rounded, color: Color(0xFF087D70)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CSP11 never stores your password or verification token '
                    'inside your learner profile.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Text(
              _message!,
              style: const TextStyle(
                color: Color(0xFF415462),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _checking ? null : _checkVerification,
              icon: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_rounded),
              label: const Text('I have verified my email'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _resending || _cooldown > 0 ? null : _resend,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _cooldown > 0
                  ? 'Resend available in ${_cooldown}s'
                  : 'Resend verification email',
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _authService.signOut,
            child: const Text('Use a different account'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Need help? csp11app@gmail.com',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF71808C), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
