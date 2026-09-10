import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/learner_profile.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/learner_profile_service.dart';
import 'auth_experience_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.authService, this.profileService});

  final AuthService? authService;
  final LearnerProfileService? profileService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthService _authService;
  late final LearnerProfileService _profileService;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  final _organization = TextEditingController();
  final _jobTitle = TextEditingController();
  final _experience = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _profileService = widget.profileService ?? LearnerProfileService();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _country,
      _phone,
      _organization,
      _jobTitle,
      _experience,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    User? createdUser;
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw StateError('No Firebase user was returned.');
      }

      await createdUser.updateDisplayName(_name.text.trim());

      final years = int.tryParse(_experience.text.trim());
      await _profileService.createProfile(
        LearnerProfile(
          uid: createdUser.uid,
          fullName: _name.text,
          email: _email.text,
          country: _country.text,
          phone: _phone.text,
          organization: _organization.text,
          jobTitle: _jobTitle.text,
          yearsExperience: years,
        ),
      );

      await _authService.sendVerificationEmail();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyAuthError(error.code));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'We could not finish creating your account. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 8 characters.';
      default:
        return 'Registration could not be completed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthExperienceShell(
      eyebrow: 'NEW LEARNER REGISTRATION',
      title: 'Your CSP11 workspace starts here.',
      subtitle:
          'Create one verified learner identity for study, questions and progress.',
      child: AuthCard(
        title: 'Create learner account',
        subtitle:
            'Only essential learner profile information is stored. '
            'Your password is never stored in the learner profile.',
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                _field(
                  controller: _name,
                  label: 'Full name',
                  icon: Icons.badge_outlined,
                  validator: _required,
                  autofill: AutofillHints.name,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _email,
                  label: 'Email address',
                  icon: Icons.alternate_email_rounded,
                  validator: _emailValidator,
                  keyboard: TextInputType.emailAddress,
                  autofill: AutofillHints.email,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _country,
                  label: 'Country',
                  icon: Icons.public_rounded,
                  validator: _required,
                  autofill: AutofillHints.countryName,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _jobTitle,
                        label: 'Job title (optional)',
                        icon: Icons.work_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _experience,
                        label: 'Years experience',
                        icon: Icons.timeline_rounded,
                        keyboard: TextInputType.number,
                        validator: _experienceValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _organization,
                  label: 'Organization (optional)',
                  icon: Icons.apartment_rounded,
                  autofill: AutofillHints.organizationName,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _phone,
                  label: 'Phone (optional)',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  autofill: AutofillHints.telephoneNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: !_loading,
                  obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _passwordValidator,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPassword,
                  enabled: !_loading,
                  obscureText: _hideConfirmPassword,
                  validator: (value) {
                    if (value != _password.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => _hideConfirmPassword = !_hideConfirmPassword,
                        );
                      },
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _register,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user_rounded),
                    label: Text(
                      _loading
                          ? 'Creating secure account...'
                          : 'Create & verify account',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    String? autofill,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_loading,
      keyboardType: keyboard,
      validator: validator,
      autofillHints: autofill == null ? null : [autofill],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if ((value ?? '').length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  String? _experienceValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final years = int.tryParse(text);
    if (years == null || years < 0 || years > 80) {
      return 'Enter 0–80.';
    }
    return null;
  }
}
