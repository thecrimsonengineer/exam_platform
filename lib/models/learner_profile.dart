class LearnerProfile {
  const LearnerProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.country,
    this.phone,
    this.organization,
    this.jobTitle,
    this.yearsExperience,
  });

  final String uid;
  final String fullName;
  final String email;
  final String country;
  final String? phone;
  final String? organization;
  final String? jobTitle;
  final int? yearsExperience;

  Map<String, Object?> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'country': country.trim(),
      if (_hasText(phone)) 'phone': phone!.trim(),
      if (_hasText(organization)) 'organization': organization!.trim(),
      if (_hasText(jobTitle)) 'jobTitle': jobTitle!.trim(),
      if (yearsExperience != null) 'yearsExperience': yearsExperience,
      'role': 'student',
    };
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
