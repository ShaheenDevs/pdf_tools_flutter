# Android Release Readiness

**Current state:** Feature implementation is being validated on a physical Android device. This project is not yet release-ready for Google Play distribution.

## Completed foundation

- [x] Offline-first document storage in app-private directories.
- [x] SQLite/Drift metadata with document/page/annotation relationships.
- [x] Camera permission declared; scanner integration uses the native scanner plugin.
- [x] App label set to **PDF Tools & Scanner**.
- [x] No broad external-storage permission is declared; user-selected import/export uses the platform file picker.
- [x] Core workflows are designed to work without account or network access.
- [x] GitHub Actions generates Android scaffolding, resolves dependencies, generates Stacked/Drift code, analyzes, runs tests, and builds a debug APK.

## Release blockers

- [ ] Replace the template application ID and namespace `com.example.pdf_tools_flutter` with a verified, publisher-controlled, globally unique Android application ID. This requires the publisher's package-name decision; do not guess it.
- [ ] Configure a production upload/release signing key through protected CI secrets or the release operator's secure local environment. Never commit keystore files or passwords.
- [ ] Create production app icons, adaptive icons, and launch/splash assets with approved brand artwork.
- [ ] Confirm final app name, support email/site, privacy policy URL, and store listing text.
- [ ] Review the final target SDK against current Google Play requirements at release time.
- [ ] Verify camera permission rationale, denial, permanent denial, and returning from Android Settings.
- [ ] Validate low-storage behavior, large PDFs/images, malformed/encrypted PDFs, and process recreation.
- [x] Add best-effort startup cleanup for app-managed `.pending` writes older than 24 hours; physical low-storage and forced-process-death scenarios still require device QA.
- [ ] Validate share/save behavior across supported Android versions and target apps.
- [ ] Complete accessibility review: TalkBack labels, text scaling, contrast, focus order, and touch targets.
- [ ] Review app size, startup time, memory use, and scanner/PDF processing performance on low- and mid-range devices.
- [ ] Prepare privacy/data-safety declarations. Current core features store documents locally; future billing, ads, OCR, and cloud features must trigger a fresh disclosure review before release.
- [ ] Produce and test a signed release AAB/APK, then install it on a clean device and verify upgrade behavior.

## Permission and data policy review

Current manifest declares camera permission only. The app stores managed document data in app-private storage and uses the platform file picker for user-selected files. Do not add broad storage permissions unless a documented feature truly requires them.

The current app has no implemented account, ads, cloud backup, or OCR network service. Do not declare those services as active in store disclosures until they are implemented. If those features are later enabled, update the privacy policy and Play Console Data safety declarations to match actual collection, sharing, retention, and deletion behavior.

## CI and release separation

GitHub Actions currently builds a **debug APK**. A passing debug build is not a production release. Production signing, release bundle generation, store metadata, privacy declarations, and publisher-owned package identity remain explicit release gates.

## Device acceptance

The user has confirmed physical-device testing for the scanner/page editor, PDF operations, annotation/signature/finishing, and share/batch workflows. Automated GitHub Actions results are tracked independently and must not be inferred from device acceptance.


Startup cleanup is isolated behind a catch-all best-effort guard. A path-provider/platform failure during optional stale-file recovery does not block app launch; locator and database initialization errors are not swallowed.
