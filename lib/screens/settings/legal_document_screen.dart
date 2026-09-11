import 'package:flutter/material.dart';

class LegalSection {
  final String heading;
  final String body;

  const LegalSection({required this.heading, required this.body});
}

class LegalDocument {
  final String title;
  final String subtitle;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
}

class Csp11LegalDocuments {
  Csp11LegalDocuments._();

  static const privacyPolicy = LegalDocument(
    title: 'Privacy Policy',
    subtitle: 'How the CSP11 app handles account and learning data.',
    sections: [
      LegalSection(
        heading: 'Information used by the app',
        body:
            'The app may use account information required for sign-in, such as your Firebase account identifier and email address. Published learning content and questions may be loaded from cloud services used by the app.',
      ),
      LegalSection(
        heading: 'Learning progress on this device',
        body:
            'Your CSP11 learning progress, Continue Learning position, and question-completion history are stored locally on the device or browser profile. Learner-owned local records are separated by the Firebase account UID so different signed-in accounts on the same device do not share progress.',
      ),
      LegalSection(
        heading: 'External contact links',
        body:
            'When you choose WhatsApp, email, or LinkedIn from Settings, the app opens the relevant external service. Any information you send through those services is handled under that service’s own privacy practices.',
      ),
      LegalSection(
        heading: 'Data choices',
        body:
            'You can sign out at any time. The Settings screen also provides a control to clear the current signed-in account’s locally stored learning progress from this device. Clearing local app data or uninstalling the app may also remove local progress.',
      ),
      LegalSection(
        heading: 'Security',
        body:
            'Reasonable technical controls are used to separate learner accounts and restrict access to published learning data. No software system can guarantee absolute security.',
      ),
      LegalSection(
        heading: 'Changes and contact',
        body:
            'This policy may be updated as the app develops. Questions about privacy or data handling can be sent to csp11app@gmail.com.',
      ),
    ],
  );

  static const termsOfService = LegalDocument(
    title: 'Terms of Service',
    subtitle: 'Basic conditions for using the CSP11 learning platform.',
    sections: [
      LegalSection(
        heading: 'Educational use',
        body:
            'CSP11 is provided as a learning, revision, and practice platform. You are responsible for how you use the material and for checking any requirements that apply to your examination, workplace, or professional activities.',
      ),
      LegalSection(
        heading: 'Accounts',
        body:
            'Keep your sign-in credentials secure and use your own account. Learner progress is associated with the signed-in Firebase UID on each device where local progress is created.',
      ),
      LegalSection(
        heading: 'Acceptable use',
        body:
            'Do not attempt to interfere with the app, bypass access controls, misuse accounts, disrupt services, or use the platform in a way that violates applicable law or the rights of others.',
      ),
      LegalSection(
        heading: 'Learning content',
        body:
            'Content may be revised, corrected, expanded, archived, or replaced as the learning platform develops. Availability of a particular Topic, Subtopic, question, or feature is not guaranteed permanently.',
      ),
      LegalSection(
        heading: 'Third-party services',
        body:
            'The app may open third-party services such as WhatsApp, email, LinkedIn, app stores, or cloud services. Their own terms and policies apply when you use those services.',
      ),
      LegalSection(
        heading: 'Updates',
        body:
            'These terms may change as new features are released. Continued use after an update means you are using the platform under the then-current terms presented in the app.',
      ),
    ],
  );

  static const legalDisclaimer = LegalDocument(
    title: 'Legal Disclaimer',
    subtitle: 'Important limits on educational and professional reliance.',
    sections: [
      LegalSection(
        heading: 'No examination guarantee',
        body:
            'Use of the CSP11 app, its questions, study material, tutoring, or study sessions does not guarantee a particular examination result, certification outcome, score, or professional credential.',
      ),
      LegalSection(
        heading: 'Educational material only',
        body:
            'The app is intended for education and revision. It is not a substitute for professional legal, engineering, medical, occupational safety, emergency, or regulatory advice for a real-world situation.',
      ),
      LegalSection(
        heading: 'Workplace decisions',
        body:
            'Do not rely on the app as the sole basis for a workplace risk decision, emergency action, compliance determination, or safety-critical instruction. Use applicable laws, standards, procedures, competent professional advice, and current organisational requirements.',
      ),
      LegalSection(
        heading: 'Third-party names and marks',
        body:
            'Unless expressly stated otherwise, third-party certification names, organisations, products, and trademarks referenced for educational context remain the property of their respective owners. Their mention does not by itself imply endorsement or affiliation.',
      ),
      LegalSection(
        heading: 'Tutoring and study sessions',
        body:
            'Requests made through the Get in Touch section for tuition, classes, or study sessions are separate communications with the developer. Availability, format, scheduling, and any commercial terms should be agreed directly before a session is confirmed.',
      ),
      LegalSection(
        heading: 'Release review',
        body:
            'This in-app disclaimer is a practical product draft and should be reviewed together with the final published Privacy Policy and Terms of Service before public release.',
      ),
    ],
  );
}

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentScreen({super.key, required this.document});

  static const _background = Color(0xFFF3F6FC);
  static const _navy = Color(0xFF102A56);
  static const _blue = Color(0xFF1E4C91);
  static const _violet = Color(0xFF5B36A8);
  static const _textPrimary = Color(0xFF18243A);
  static const _textMuted = Color(0xFF718096);
  static const _border = Color(0xFFE1E7F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(document.title),
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F6FC), Color(0xFFF7F9FC), Color(0xFFF8F7FC)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_navy, _blue, _violet],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            document.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            document.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...document.sections.map(
                      (section) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.heading,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              section.body,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11.5,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
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
