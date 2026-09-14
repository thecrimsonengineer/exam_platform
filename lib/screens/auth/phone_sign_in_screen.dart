import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import 'auth_experience_shell.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  late final AuthService _authService;

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmationResult;

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _normalisePhoneNumber(String raw) {
    return raw.trim().replaceAll(RegExp(r'[\s()\-]'), '');
  }

  bool _isValidE164(String value) {
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value);
  }

  String _firebaseMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-phone-number' =>
        'Enter a valid phone number with country code, for example +919876543210.',
      'too-many-requests' =>
        'Too many verification attempts were made. Please try again later.',
      'quota-exceeded' =>
        'The SMS verification quota has been reached. Please try again later.',
      'invalid-verification-code' =>
        'That verification code is incorrect. Check the SMS and try again.',
      'session-expired' =>
        'This verification session expired. Request a new code.',
      'network-request-failed' =>
        'A network error interrupted verification. Check your connection and try again.',
      _ => error.message ?? 'Phone verification could not be completed.',
    };
  }

  Future<void> _sendCode({bool resend = false}) async {
    final phoneNumber = _normalisePhoneNumber(_phoneController.text);

    if (!_isValidE164(phoneNumber)) {
      setState(() {
        _errorMessage =
            'Use international format with country code, for example +919876543210.';
        _statusMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = resend ? 'Requesting a new code...' : 'Sending code...';
    });

    try {
      if (kIsWeb) {
        final confirmation = await _authService.startWebPhoneSignIn(
          phoneNumber: phoneNumber,
        );

        if (!mounted) return;
        setState(() {
          _webConfirmationResult = confirmation;
          _codeSent = true;
          _statusMessage = 'Verification code sent.';
          _isLoading = false;
        });
        return;
      }

      await _authService.startNativePhoneVerification(
        phoneNumber: phoneNumber,
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) async {
          try {
            await _authService.signInWithPhoneCredential(credential);
            await _finishSuccessfulSignIn();
          } on FirebaseAuthException catch (error) {
            if (!mounted) return;
            setState(() {
              _errorMessage = _firebaseMessage(error);
              _statusMessage = null;
              _isLoading = false;
            });
          }
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _errorMessage = _firebaseMessage(error);
            _statusMessage = null;
            _isLoading = false;
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
            _statusMessage = 'Verification code sent.';
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _firebaseMessage(error);
        _statusMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'We could not start phone verification. Check your connection and Firebase phone-auth setup.';
        _statusMessage = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _errorMessage = 'Enter the 6-digit verification code from the SMS.';
        _statusMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Verifying code...';
    });

    try {
      if (kIsWeb) {
        final confirmation = _webConfirmationResult;
        if (confirmation == null) {
          throw StateError('No active web phone-verification session.');
        }
        await confirmation.confirm(code);
      } else {
        final verificationId = _verificationId;
        if (verificationId == null) {
          throw StateError('No active phone-verification session.');
        }

        await _authService.confirmNativePhoneCode(
          verificationId: verificationId,
          smsCode: code,
        );
      }

      await _finishSuccessfulSignIn();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _firebaseMessage(error);
        _statusMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'The verification session is no longer available. Request a new code.';
        _statusMessage = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _finishSuccessfulSignIn() async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AuthExperienceShell(
      eyebrow: 'CSP11 SECURE ACCESS',
      title: 'Verify your phone.',
      subtitle:
          'Use a one-time SMS code to securely access your learner account.',
      child: AuthCard(
        title: _codeSent ? 'Enter verification code.' : 'Sign in by phone.',
        subtitle: _codeSent
            ? 'Enter the 6-digit code sent to ${_phoneController.text.trim()}.'
            : 'Enter your mobile number in international format.',
        children: [
          TextField(
            controller: _phoneController,
            enabled: !_isLoading && !_codeSent,
            keyboardType: TextInputType.phone,
            textInputAction: _codeSent
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: _codeSent ? null : (_) => _sendCode(),
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '+919876543210',
              prefixIcon: Icon(Icons.phone_iphone_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _codeController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              onSubmitted: (_) => _verifyCode(),
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(
                labelText: '6-digit SMS code',
                prefixIcon: Icon(Icons.password_rounded),
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: 14),
            _PhoneMessagePanel(message: _statusMessage!, isError: false),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _PhoneMessagePanel(message: _errorMessage!, isError: true),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isLoading
                  ? null
                  : _codeSent
                  ? _verifyCode
                  : _sendCode,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _codeSent
                          ? Icons.verified_user_rounded
                          : Icons.sms_rounded,
                    ),
              label: Text(
                _codeSent ? 'Verify and sign in' : 'Send verification code',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : () => _sendCode(resend: true),
              child: const Text('Resend code'),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _codeSent = false;
                        _verificationId = null;
                        _resendToken = null;
                        _webConfirmationResult = null;
                        _codeController.clear();
                        _errorMessage = null;
                        _statusMessage = null;
                      });
                    },
              child: const Text('Use a different phone number'),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'By continuing, your phone number is sent to Google/Firebase for authentication and abuse prevention. Standard SMS charges may apply.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF71808C),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneMessagePanel extends StatelessWidget {
  const _PhoneMessagePanel({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF087D70);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
