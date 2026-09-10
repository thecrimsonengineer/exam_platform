import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import 'auth_experience_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.authService,
  });

  final String initialEmail;
  final AuthService? authService;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final AuthService _authService;
  late final TextEditingController _email;

  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address.');
      return;
    }

    setState(() {
      _loading = true;
      _sent = false;
      _error = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (_) {
      if (!mounted) return;
      // Neutral wording avoids exposing whether an account exists.
      setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthExperienceShell(
      eyebrow: 'ACCOUNT RECOVERY',
      title: 'Get back into your study path.',
      subtitle: 'Password recovery is handled through Firebase Authentication.',
      child: AuthCard(
        title: 'Reset your password',
        subtitle:
            'Enter the email used for your learner account. We will send recovery instructions.',
        children: [
          TextField(
            controller: _email,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _sendReset(),
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.alternate_email_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_sent) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'If an account exists for that email, recovery instructions '
                'have been sent. Check Inbox and Spam.',
                style: TextStyle(
                  color: Color(0xFF087D70),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _loading ? null : _sendReset,
              icon: const Icon(Icons.mark_email_read_outlined),
              label: Text(_loading ? 'Sending...' : 'Send reset email'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
