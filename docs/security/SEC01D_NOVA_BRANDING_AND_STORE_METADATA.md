# SEC-01D — CSP 11 Nova app identity and store metadata

**Approved display name:** `CSP 11 Nova: CSP Exam Prep.`  
**Character count:** 28 (Google Play maximum: 30).  
**Android package candidate:** `com.csp11.examplatform` (NOT registered/verified in Play Console yet).  
**Business model:** Completely free; do not introduce in-app billing or premium entitlements.  
**Firebase:** existing project `csp11-exam-platform`; authentication must stay intact.  
**Frozen source:** `phase-post-rel-gov-global-navigation-motion-integration-closed@156ea074e1f420672490511a01117804dc22ce74`.

## Implemented: brand only, no package migration

- Android manifest `android:label` references `@string/app_name`; `android/app/src/main/res/values/strings.xml` uses the **exact approved full name**.
- Flutter `MaterialApp.title` uses the approved full name.
- Web `<title>`, Apple home-screen name, and PWA `manifest.json` use the new brand; the web/PWA short name is `CSP 11 Nova` to fit mobile surfaces.
- Read-only `tools/security/sec01d_branding_preflight.py` verifies name consistency in all surfaces.
- Negative and happy-path tests `tools/security/test_sec01d_branding_preflight.py` are included in the SEC-01C CI guard suite.
- The controlled Play App Bundle job rechecks branding before building.
- Existing app `applicationId`, Android namespace, Kotlin activity, `google-services.json`, `firebase_options.dart`, `firebase.json`, Supabase and FR8/FR9/FR10 source are **not changed**.

**Practical note:** Some Android launchers may visually truncate the 28-character full label depending on screen size. The store listing uses the exact approved name.

## Suggested Google Play listing copy (owner review before publishing)

**App name:** CSP 11 Nova: CSP Exam Prep.

**Short description:**
> Independent CSP exam preparation with practice questions and study tools.

**Full description draft:**

CSP 11 Nova is an independent study companion for people preparing for the Certified Safety Professional (CSP) examination.

Study occupational safety and health topics, practise with exam-style questions, and revisit concepts through organised learning material and flashcards. Use learning and progress tools to structure your revision and identify topics that need further attention.

The app is offered completely free. A learner account and an internet connection may be required to access protected learning content.

**Independence notice:** CSP 11 Nova is an independently developed study aid and is not affiliated with, endorsed by, or an official product of the Board of Certified Safety Professionals (BCSP). The app does not contain official examination questions and does not guarantee examination success.

**Do not claim:** official BCSP partnership, official or recalled exam questions, guaranteed pass, unsupported question-count statistics, no advertising unless verified, or compliance certifications not actually awarded.

## Branding and intellectual property acceptance

- [x] Exact requested name recorded and added to app metadata.
- [x] Name under the 30-character Google Play title limit.
- [ ] Owner confirms brand/trademark permissions where required and ensures no misleading affiliation.
- [ ] Owner confirms Play Console accepts the exact title and package ID under their account.
- [ ] Verify installed Android launcher name on device.
- [ ] Verify Play listing screenshots and icon use original branding and no third-party logos.
- [ ] Final review of descriptions, privacy policy, data safety, and accessibility.

## Sources

- Google Play app name length: https://support.google.com/googleplay/android-developer/answer/9859152
- Google Play metadata/impersonation: https://support.google.com/googleplay/android-developer/answer/18265346
- Flutter Android label: https://docs.flutter.dev/deployment/android
- BCSP credential and marks context: https://www.bcsp.org/certified-safety-professional-csp
- BCSP site terms: https://www.bcsp.org/terms-of-use
