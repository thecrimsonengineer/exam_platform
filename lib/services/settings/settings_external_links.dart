class SettingsExternalLinks {
  SettingsExternalLinks._();

  static final Uri whatsApp = Uri.parse('https://wa.me/918129659572').replace(
    queryParameters: {
      'text':
          'Hi Naveed, I am contacting you through the CSP11 app regarding tuition, a study session, or classes.',
    },
  );

  static final Uri email = Uri(
    scheme: 'mailto',
    path: 'csp11app@gmail.com',
    queryParameters: {
      'subject': 'CSP11 tuition / study session enquiry',
      'body':
          'Hi Naveed,\n\nI am contacting you through the CSP11 app regarding tuition, a study session, or classes.\n',
    },
  );

  static final Uri linkedIn = Uri.parse(
    'https://www.linkedin.com/in/naveedcsp',
  );
}
