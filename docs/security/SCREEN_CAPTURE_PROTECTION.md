# CSP11 Security S1 - Android Screen Capture Protection

## Status

IMPLEMENTED / HUMAN DEVICE REVIEW REQUIRED

## Scope

This security slice protects the entire Android application window.

The protection is not limited to quizzes. It applies while the CSP11 app
window is active, including learner and admin surfaces.

## Android enforcement

`MainActivity` adds:

`WindowManager.LayoutParams.FLAG_SECURE`

Android documents `FLAG_SECURE` as a secure-window flag that prevents the
window from appearing in screenshots or on non-secure displays. It also
protects the window during supported screen-capture / media-projection flows.

No Flutter package is required. The protection is enforced by the native
Android window.

## Expected device behavior

While CSP11 is visible on Android:

- screenshots should be blocked or produce a protected/blank result depending
  on the Android/device UI
- screen recordings should not contain the protected CSP11 window
- screen sharing / projection should not expose the protected window where
  Android honors secure-window protection
- recent-app thumbnails may be blanked/protected by the platform

## Boundaries

This is a deterrence and platform-level content protection control. It cannot:

- stop somebody photographing the physical display with another camera
- guarantee protection on a compromised/rooted operating system
- control external capture hardware after pixels leave the trusted device path

## iOS / iPadOS

iOS does not expose a public API equivalent to Android `FLAG_SECURE` that
guarantees screenshots are disabled before capture.

Apple provides capture-state APIs for detecting active screen recording,
mirroring, screen sharing, and remote control so sensitive UI can be hidden
while capture is active. Screenshot notification is post-capture.

Therefore iOS protection should be implemented as a separate Mac-validated
security slice using an active-capture privacy shield and app-switcher privacy
cover. It should not be described as guaranteed screenshot prevention.

## Web / Windows

A browser or desktop Flutter app cannot reliably prevent operating-system or
external screenshot/screen-recording tools. Watermarking and obscuring on
background/visibility changes can be added as deterrence, but they are not
equivalent to Android `FLAG_SECURE`.

## Phase M safety

Security S1 is independent of Learning Twin behavior.

It does not:
- change question selection
- change Firestore rules
- expose question answers
- modify M6.1 practice logic
- change Learning Twin decisions
- push, tag, or merge
