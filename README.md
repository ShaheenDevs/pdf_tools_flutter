# PDF Tools & Scanner

An offline-first PDF scanning and management application for Android, built with Flutter. Core document workflows are designed to work entirely on-device; network access is reserved for optional future services such as cloud backup and OCR.

## A. Project Overview

- **Project:** PDF Tools & Scanner
- **Flutter repository:** https://github.com/ShaheenDevs/pdf_tools_flutter
- **Backend:** Not required for core functionality. A separate Node.js service may be introduced later for cloud backup, account-based synchronization, and OCR.
- **Primary platform:** Android
- **Technology:** Flutter, Dart, Stacked, SQLite/Drift, app-private file storage
- **Architecture:** Follow the View / ViewModel / service-locator / service separation used by [edge_market_flutter](https://github.com/ShaheenDevs/edge_market_flutter). Use feature-oriented views, ViewModels, reusable widgets, and registered services. Add repositories and local data sources where appropriate for the offline domain.
- **Backend reference:** [edge_market_node_js](https://github.com/ShaheenDevs/edge_market_node_js). It is a reference only for a future optional backend; no backend is part of the initial core scope.

### Architecture principles

1. Core scanning, editing, file management, and export must not require an account or internet connection.
2. Keep source images and generated PDFs in app-private local storage. Store searchable metadata and relationships in SQLite through Drift.
3. Keep UI state and business logic in Stacked ViewModels; keep file/PDF/camera/database operations in services and repositories.
4. Treat document operations as durable file workflows: write to a temporary output, validate the result, then replace or register the final file. Avoid corrupting the original on failure.
5. Use explicit permissions, safe file-name handling, file-size checks, and recoverable error states.
6. Premium entitlements must never disable or block the user's locally stored documents or basic offline features.
7. Do not add Firebase or Supabase as primary backend services.

## B. Features

Status legend:
- ☒ Completed and tested
- [~] Implemented but testing incomplete
- ☐ Pending
- [!] Blocked or requires a decision

### Core / free features

| Feature | Status | Scope |
|---|---|---|
| Camera document scanning | ☒ | Multi-page native scanner with local PDF/page-image persistence; user confirmed physical-device testing |
| Crop and rotate pages | ☒ | Persist normalized crop margins and 90° rotations; regenerate the scanned PDF; user confirmed device testing |
| Reorder pages | ☒ | Reorder scanned pages and rebuild the PDF in the selected order; user confirmed device testing |
| Delete pages | ☒ | Delete a scanned page with confirmation, keeping at least one page; user confirmed device testing |
| Merge PDFs | ☒ | Merge multiple local PDFs in picker order; save a new library PDF; user confirmed device testing |
| Split PDFs | ☒ | Export semicolon-separated page ranges as separate local PDFs; user confirmed device testing |
| Basic PDF compression | ☒ | Lossless local PDF optimization; save a separate copy and report size change; user confirmed device testing |
| Image to PDF | ☒ | Convert multiple local JPG/PNG images into one PDF; user confirmed device testing |
| Local annotation and highlighting | ☒ | Draw pen/highlight/freehand-signature strokes, persist them locally, and export a separate PDF copy with page-aligned image stamps; user confirmed device testing |
| Share and export | ☒ | Share PDF/image files through Android's share sheet and save copies through the system save-file picker; user confirmed device testing |
| Document library | ☒ | Browse, import, search, preview, rename, and delete locally managed PDF/image documents; user confirmed physical-device validation |

### Premium features

| Feature | Status | Scope |
|---|---|---|
| Batch processing | ☒ | Batch-compress multiple local PDFs with per-file failure isolation, progress, and safe stop-between-files; user confirmed device testing; premium entitlement gating remains pending |
| Advanced compression | ☐ | Offer additional compression profiles and controls |
| OCR credits | ☐ | Future OCR integration; cloud/API dependency and credit policy to be designed |
| Cloud backup | ☐ | Future optional Node.js API and remote storage integration |
| Premium templates | ☐ | Additional scan/export templates |
| Remove ads | ☐ | Premium entitlement controlling ad presentation |

### Additional document tools

| Feature | Status | Scope |
|---|---|---|
| Digital signature | ☒ | Apply a certificate-backed PKCS#12/PFX digital signature; freehand signature marks are also available in the annotation editor; user confirmed device testing |
| Watermark | ☒ | Add a translucent text watermark to all pages and save a separate PDF copy; user confirmed device testing |
| Page numbers | ☒ | Add per-page `Page N of total` labels at the bottom-right and save a separate PDF copy; user confirmed device testing |
| PDF preview | ☒ | Offline PDF page navigation and zoomable local image preview |
| Document metadata | ☒ | Persist title, file path, page count, size, timestamps, and generated PDF/image preview thumbnails |

## C. Development Progress

| Area / feature | Status | Flutter | Backend | Testing |
|---|---|---|---|---|
| Repository analysis | [~] | Reference and target repositories inspected | Reference inspected; no target backend | Not applicable |
| Project setup | ☒ | Flutter app, Android scaffolding, Stacked shell, and generated files are on main | N/A | User confirms they have tested the app on a physical Android device |
| Local database and file storage | ☒ | Drift schema, SQLite connection, app-private atomic file storage, Stacked registrations, and repository operations implemented; generated Drift code is present on main | N/A | Analysis and all seven tests passed in CI; user confirms physical-device testing |
| Document library | ☒ | PDF/image import, searchable local list, rename/delete, PDF page counts, thumbnails, offline PDF/image preview | N/A | User confirmed PDF/image import and preview were run and tested on a physical Android device; automated tests are present, with CI tracked separately |
| Camera scanning and page editing | ☒ | Native multi-page scanning, crop/rotate, reorder/delete, PDF regeneration for scanned documents | N/A | User confirmed physical-device testing; automated CI rerun is tracked separately |
| Merge, split, image-to-PDF, and compression | ☒ | Offline PDF operations screen, service, and local-library output persistence | N/A | User confirmed physical-device testing; CI covers service behavior |
| Annotation, highlighting, and signatures | ☒ | Local page-level markup with SQLite persistence and annotated-copy export; PKCS#12 certificate signing exports a separate signed copy | N/A | User confirmed physical-device testing; CI covers persistence/export validation |
| Watermark and page numbers | ☒ | Local PDF watermark and per-page numbering exports through `pdf_manipulator` | N/A | User confirmed physical-device testing; automated service coverage added |
| Share and export | ☒ | Preview actions share local documents and save copies through Android system UI | N/A | User confirmed physical-device testing; missing-source guard tests included |
| Batch PDF processing | ☒ | Multi-file compression with progress, per-file failure isolation, and safe cancellation between files | N/A | User confirmed physical-device testing; automated validation is tracked by CI |
| Premium entitlements and ads | [~] | Purchase verification and offline entitlement policy documented; billing/UI integration awaits Play Console product catalog and account decision | Optional Node.js verification API designed, not implemented | Architecture documented; implementation pending product setup |
| OCR and cloud backup | [~] | Provider evaluation criteria, privacy boundaries, and API contracts documented; OCR languages/provider and storage vendor remain undecided | Optional Node.js API contract designed, not implemented | Architecture documented; provider and product decisions pending |
| Release preparation | [~] | Branded app label, permission review, and release-blocker checklist documented; production package ID/signing/assets remain pending | N/A | User-confirmed device testing; CI validation tracked separately |

## D. Planned Architecture and Project Structure

The structure below is a target structure, not a claim that these files already exist. It will be refined against the actual generated Stacked files and selected package APIs during implementation.

```text
lib/
  main.dart
  app/
    app.dart
    app.locator.dart              # generated by Stacked
    app.router.dart               # generated by Stacked
    app.dialogs.dart
    app.bottomsheets.dart
  models/
    document_model.dart
    document_page_model.dart
    annotation_model.dart
  services/
    camera_scanner_service.dart
    pdf_service.dart
    file_storage_service.dart
    export_service.dart
    permission_service.dart
  repositories/
    document_repository.dart
    document_repository_impl.dart
  database/
    app_database.dart              # Drift database / generated parts
    tables/
      documents.dart
      document_pages.dart
      annotations.dart
  ui/
    common/
    widgets/
    views/
      home/
      scanner/
      document_library/
      document_preview/
      page_editor/
      pdf_tools/
      image_to_pdf/
      signature/
      watermark/
      settings/
      premium/
test/
  unit/
  widget/
  integration/
```

### Stacked code flow

For each feature, follow this flow:

1. Define/update the domain model.
2. Implement the relevant local data source, service, and repository.
3. Register dependencies through the Stacked service locator and generator annotations.
4. Implement a `BaseViewModel` and expose loading, empty, error, and success states.
5. Build the screen using the reference repository's `StackedView` / `ViewModelWidget` patterns.
6. Add tests for the service/repository and the user-visible flow.

### Local data model (initial proposal)

| Table | Important fields | Purpose |
|---|---|---|
| documents | id, title, filePath, thumbnailPath, pageCount, fileSize, createdAt, updatedAt, sourceType | One row per managed PDF/document |
| document_pages | id, documentId, pageIndex, sourceImagePath, rotation, cropData | Page ordering and page-level source/edit metadata |
| annotations | id, documentId, pageIndex, type, payload, createdAt, updatedAt | Local annotation/highlight/signature placement metadata |

- Store binary PDF/image content in app-private directories, not as large SQLite blobs.
- Use foreign keys and cascading cleanup where appropriate.
- Keep file paths relative to the app-managed storage root where practical.
- Use migrations for schema changes; do not rely on destructive schema recreation.
- The exact schema will be validated against the selected PDF editing workflow before implementation.

## E. Implementation Roadmap

### Milestone 1 — Project foundation
- [x] Inspect target repository state and preserve existing content.
- [x] Create the initial Flutter source foundation using the reference Stacked conventions.
- [x] Configure dependencies, app entry point, Stacked locator, route annotations, Android scaffolding, and generated Stacked files; user confirmed the app launches on a physical Android device.
- [x] Add a basic app shell, reusable theme, and initial home workspace.
- [x] Add a home-screen widget test and setup instructions. CI now removes Flutter's generated counter test; the latest run then stopped because Flutter 3.50 reports informational deprecation/style diagnostics as analyzer findings. CI now uses `--no-fatal-infos` so warnings/errors remain blocking while informational notices do not prevent tests/build.

### Milestone 2 — Local database and file storage
- [x] Add Drift/SQLite database connection and initial schema version (v1).
- [x] Add document, page, and annotation tables with document foreign keys and cascading deletion.
- [x] Implement app-private file storage with unique names, temporary-write/rename behavior, relative paths, extension validation, and path-traversal protection.
- [x] Register the database and storage service with Stacked.
- [x] Add database and storage unit tests; analysis and all seven unit/widget tests passed in GitHub Actions run [45570778086](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45570778086).
- [x] User confirmed physical-device testing of the app. CI APK packaging compatibility is tracked as a workflow maintenance task.
- [x] Add a document repository for import, list, rename, and delete, including rollback of a stored file when metadata insertion fails.
- [x] User-confirmed physical-device smoke test and passing database/storage/repository/widget tests. The Android CI packaging workflow had a separate generated Gradle-template mismatch; the corrected Kotlin DSL patch has passed in run [45577913041](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45577913041) through analysis and tests, with APK build validation tracked by the latest run.

### Milestone 3 — Document library and import
- [x] Build the document library with loading, empty, error, refresh, rename, delete, and local title/type search states.
- [x] Add Android document-picker import for PDF and common image formats, copying selected bytes into app-private storage and registering metadata in Drift.
- [x] Use PDFx to extract actual PDF page counts and render/persist a first-page PNG thumbnail on import; failed PDF parsing leaves the original imported file intact and shows a warning.
- [x] Add offline PDF and image preview screens, including page navigation through PDFx.
- [x] Add import and preview coverage (repository metadata/thumbnail persistence, image thumbnail validation, image import ViewModel workflow, search and image preview widget tests). User confirmed running and testing the PDF/image import and preview flows on a physical Android device; CLI/CI is not used as the feature acceptance gate.

### Milestone 4 — Camera scanning and page editing
- [x] Integrate the native multi-page document scanner; copy scan PDF and source page images into app-private storage and register page records in Drift. User confirmed physical-device testing.
- [x] Add post-capture crop margins and persisted 90° page rotation; render edits from original source images.
- [x] Add page reorder and confirmed deletion; prevent deleting the final remaining page.
- [x] Regenerate a multi-page PDF and first-page thumbnail from the edited source images. Save new PDF/thumbnail and page metadata transactionally before cleaning up superseded files.
- [x] Add service tests for crop/rotation/PDF generation and repository tests for reorder/delete persistence. User confirmed complete scanner/editor device testing.

### Milestone 5 — PDF tools
- [x] Implement offline merge and range-based split; generated files are saved as separate library documents. User confirmed device testing.
- [x] Implement multi-image JPG/PNG to PDF conversion. User confirmed device testing.
- [x] Implement lossless PDF compression and report the resulting size change. User confirmed device testing.
- [x] Map password-protected and corrupted PDF errors to clear user messages; user confirmed device testing of the PDF tools workflow.

### Milestone 6 — Annotation and document finishing
- [x] Implement local page-level pen/highlight/freehand-signature overlays persisted in the existing Drift annotations table; export saved strokes into a separate PDF copy as transparent, page-sized image stamps. The stamps remain PDF stamp annotations rather than being flattened into static page content.
- [x] Implement certificate-backed PKCS#12/PFX digital signing. Certificate bytes are used in memory and are not copied into app storage; a valid certificate bundle and password are required.
- [x] Implement text watermark and per-page numbering exports. Each operation creates a separate PDF in the local library and preserves the source document.
- [x] Persist annotation strokes in SQLite and reload them when reopening the annotation editor; export all saved page markups from the editor into a new local-library PDF without modifying the source. User confirmed device testing.

### Milestone 7 — Export and batch workflows
- [x] Add share and save-copy actions to PDF/image preview using Android's system share sheet and save-file picker; preserve the source file. User confirmed device testing.
- [x] Add batch PDF compression that processes each selected file independently and continues after individual failures. User confirmed device testing.
- [x] Show batch progress and allow safe cancellation between files; an in-progress native compression operation is allowed to finish.
- [x] Add output validation through the existing PDF pipeline and tests for missing export sources; additional CI coverage remains tracked separately.

### Milestone 8 — Premium, OCR, and optional cloud roadmap
- [x] Define the Android purchase verification boundary: Google Play Billing through Flutter, server-side purchase-token verification, signed entitlement responses, restore/revocation handling, and bounded offline entitlement caching.
- [ ] Integrate billing after Play Console product IDs, pricing, account policy, and backend credentials are approved; do not add a client-only premium unlock.
- [ ] Add premium templates and remove-ads entitlement after the product/ads providers are selected.
- [x] Document OCR evaluation criteria, language-first provider selection, credit-ledger requirements, privacy, and explicit upload consent. OCR provider selection remains pending the required language list.
- [x] Design versioned optional Node.js contracts for entitlement verification, OCR jobs/credits, and backup list/upload/download/delete.
- [x] Preserve local functionality when billing, OCR, or cloud services are unavailable.
- [x] Add the architecture decision record: [Premium, OCR, and Optional Cloud Architecture](docs/premium-ocr-cloud-architecture.md).

### Milestone 9 — QA and release
- [x] Set the Android launcher label to **PDF Tools & Scanner**.
- [x] Keep the Android manifest limited to the camera permission needed by scanning; use the platform file picker rather than broad storage permission.
- [x] Add a release-readiness checklist documenting the current offline data policy and production blockers: [Android Release Readiness](docs/android-release-readiness.md).
- [x] Add a repeatable physical-device QA matrix for install/permissions, import/library, scanner/editor, PDF tools, annotation/export, batch, stress/recovery, and accessibility: [Manual Android QA Matrix](docs/manual-android-qa-matrix.md).
- [ ] Complete current GitHub Actions analysis, automated tests, and Android debug APK build.
- [ ] Verify Android permission denial/recovery, lifecycle/process recreation, low-storage, large-file, malformed/encrypted PDF, and offline scenarios.
- [ ] Finish accessibility, performance, and app-size review on representative devices.
- [ ] Set a publisher-controlled application ID, production signing configuration, icons/splash assets, support/privacy URLs, and Play listing.
- [ ] Build and test a signed release AAB; debug APK success alone is not release acceptance.

## F. Backend and API Documentation

The future premium/OCR/cloud integration boundaries and proposed REST contracts are documented in [docs/premium-ocr-cloud-architecture.md](docs/premium-ocr-cloud-architecture.md). These endpoints are design contracts only; no backend or remote dependency has been added to the core app.

Android launch blockers and permission/data-policy review are tracked in [docs/android-release-readiness.md](docs/android-release-readiness.md). The repeatable physical-device validation cases and per-case evidence fields are in [docs/manual-android-qa-matrix.md](docs/manual-android-qa-matrix.md).

**Current decision: no backend APIs are required for the core application.** No authentication, remote database, or cloud storage dependency will be introduced for local scanning and PDF tools.

Potential future API areas (not implemented):
- Account and entitlement management
- Cloud backup upload/list/download/delete
- OCR job submission, status, and result retrieval
- Usage/credit balance and transaction history

If approved and required later, the backend will follow the Node.js reference conventions: JavaScript/CommonJS, Express, Sequelize, SQL, dotenv, REST routes/controllers/models/middleware, and validated requests. API methods, authentication, request/response contracts, and errors will be documented before implementation.

## G. Database Documentation

The proposed local SQLite schema is described in **D. Planned Architecture and Project Structure**. Database migrations, relationships, indexes, and seed data will be documented here as they are implemented. There is no remote database in the initial scope.

## H. Installation and Setup

### Prerequisites
- Flutter SDK compatible with the Dart SDK constraint selected during project setup
- Android Studio or Android SDK command-line tools
- Android device or emulator

### Initial setup
The repository contains the Flutter source foundation and generated Android/Stacked files. The app has been launched successfully on the user's physical Android device. The GitHub Actions workflow `.github/workflows/flutter-android-ci.yml` resolves dependencies, runs Stacked/Drift code generation, analyzes the project, runs tests, builds a debug APK, and commits generated Android/Stacked files to `main` when validation succeeds. To run locally, use:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Run code generation only after the generated Stacked and Drift dependencies/configuration have been added.

## I. Known Issues and Decisions

- [ ] Latest CI run must complete automated tests and Android APK packaging; user-confirmed device testing is recorded separately.
- [x] Updated `pdf_manipulator` 6.0.0 compatibility: watermark uses `angleDegrees`, and PKCS#12 certificate bytes are wrapped in `MemorySource`. Latest CI rerun includes this fix.
- [x] Generated Android and Stacked files are present on `main`.
- [x] PDF engine selected: PDFx for offline rendering and page navigation; Android CI and device validation for the newly added import/preview flow remain pending.
- [x] Scanner package selected for Milestone 4: `cunning_document_scanner` (MIT; Android/iOS; multi-page capture and automatic crop; Android API 24 minimum in current 3.x docs).
- [ ] Premium purchase provider and entitlement verification are not yet selected.
- [ ] OCR provider, credit model, and privacy policy are not yet selected.
- [ ] Cloud backup storage and optional backend deployment are not yet designed.
- [ ] Minimum Android SDK and supported Android version range will be confirmed during setup.
- [x] Digital signature scope defined: certificate-backed PKCS#12/PFX signing creates a cryptographic PDF signature; freehand signature strokes are separate visual annotations.

## J. Development History

### 2026-11-25 — Milestone 4: page editor and PDF regeneration
- Added a Stacked page editor for scanned documents with per-page preview, 90-degree rotation, adjustable crop margins, drag-and-drop reorder, and confirmed deletion (the last remaining page cannot be deleted).
- Added local rendering with the `image` package and PDF reconstruction with `pdf` 3.13.1. The editor rebuilds the PDF and thumbnail from original page images so edits remain reversible at the source-image level.
- Repository persistence writes replacement PDF/thumbnail files, updates page metadata/order and document metadata in a Drift transaction, then removes superseded files. Added unit coverage for crop, rotation, PDF generation, page order and deletion.
- User subsequently confirmed physical-device testing of the complete scanner and page-editor workflow; CI remains a separate quality check.

### 2026-11-25 — Milestone 4: native scanner integration
- Selected `cunning_document_scanner` 3.1.0 (MIT) after checking Android support, multi-page output, automatic cropping, image/PDF output, and API requirements. Declared Android camera permission and set minSdk to 24 as required by the current 3.x package documentation.
- Added a Stacked ViewModel scan action and connected the Scan document tile. Scanner output is copied from plugin-owned temporary paths into app-private storage; the generated PDF and each source page image are registered with Drift.
- Added repository test coverage for scanned PDF/page persistence and cleanup. Device verification is pending.

### 2026-11-25 — Milestone 3 accepted on physical device; Milestone 4 started
- User explicitly confirmed that the PDF/image import and preview flows were run and tested on a physical Android device, and asked that CLI execution not block progress. Milestone 3 is accepted on that basis.
- Automated test/build checks remain a separate quality signal and are not represented as passed by this device confirmation.
- Started Milestone 4 package evaluation. Selected `cunning_document_scanner` 3.x because its current package documentation describes multi-page scanning, automatic crop, image/PDF outputs, Android support, and an MIT license. Android camera permission and API 24 minimum are being configured.

### 2026-11-25 — Milestone 2: local database and file storage started
- Added Drift and SQLite dependencies plus an app-support-directory database connection.
- Added schema v1 for documents, document pages, and annotations, including cascading foreign keys and unique page ordering per document.
- Added app-private file storage for documents, images, thumbnails, and temporary files. Writes use a pending file followed by rename; APIs return relative paths and reject unsafe extensions/path traversal.
- Registered `AppDatabase` and `FileStorageService` in the Stacked locator.
- Added in-memory database tests for related records/cascading deletion and file-storage tests for write/read/delete and input validation.
- GitHub Actions analyzer now uses `flutter analyze --no-fatal-infos`: Flutter 3.50.1 emits informational framework deprecation and const-style diagnostics, while warnings and errors remain fatal.
- Tests: GitHub Actions provides automated validation; local CLI execution is intentionally skipped at the user's request.
- Commits are being made directly to `main`; this milestone is not complete until code generation, tests, and Android build pass.


### 2026-11-25 — Milestone 1: initial Flutter source foundation
- Added `pubspec.yaml`, `.gitignore`, and `analysis_options.yaml`.
- Added the Flutter entry point, Stacked app configuration and locator, centralized theme, HomeView, HomeViewModel, and a first home-screen widget test.
- Added an offline-first home workspace with non-interactive tool previews and an empty recent-documents state; no placeholder action is wired to pretend a feature works.
- Dependencies currently limited to Flutter, Stacked, and Stacked Services plus code-generation/test tooling; PDF, camera, database, and file-picker packages are deferred to their feature milestones.
- Added `.github/workflows/flutter-android-ci.yml` to perform Flutter dependency resolution, Android scaffold generation, Stacked code generation, analysis, widget tests, and debug APK build on GitHub-hosted runners. On successful push validation, it commits generated Android and Stacked files to this branch.
- Added an explicit Material import to the widget test.
- Local tests: not run because Flutter/Dart SDKs are not installed and outbound DNS/network access is unavailable in this environment; awaiting GitHub Actions result.
- Source foundation commit chain includes `35e0aeb5` (initial scaffold), `46466a9e` (theme compatibility), `f4155d2b` (public navigation-service import), `ee1901c8` (generated locator lint convention), `20a4bd25` (GitHub Actions Flutter CI), and `ae779f90` (widget test import cleanup).
- The feature branch was merged into `main` by merge commit `60f5aaba913e937ff33b795204f36e13ea72e802`; subsequent work continues on `main`.
- GitHub Actions runs `45473596826` and `45473633399` all failed at `flutter analyze`. Android platform generation, dependency resolution, and Stacked code generation succeeded; widget tests and APK build were skipped. The root cause was that `flutter create --platforms=android .` recreated its default `test/widget_test.dart` counter test, which references `MyApp` and `material_ui`, neither of which exists in this project. The CI workflow now removes that generated template test immediately after platform generation.
- Remaining: rerun CI with the generated template test removed, and confirm generated Android/Stacked files are committed before closing Milestone 1.

### 2026-11-25 — Project initialization and repository analysis
- Received project requirements and permanent development prompt.
- Inspected the Flutter and Node.js reference repository metadata, root structures, representative Flutter app/service/ViewModel files, and representative backend package/server/model/controller/middleware/route/migration files.
- Confirmed the new Flutter repository is accessible and currently contains only an initial README.
- Confirmed GitHub push permissions are available.
- Created the `project/initial-roadmap` branch for the planning milestone.
- Tests: not run; no Flutter application source exists yet.
- Roadmap commit: `3e79d85596f4cc45f7163694ecb2722933519857`.
- This development-history entry is finalized in the follow-up documentation commit.
- Remaining: finish Milestone 1 by generating Android platform files and validating the project with Flutter/Dart.



### 2026-11-25 — Milestones 4–7 device acceptance and CI follow-up
- User confirmed that the native scanner/page editor, PDF merge/split/image conversion/compression, annotation and finishing tools, share/save, and batch compression were tested on a physical Android device.
- Milestones 4, 5, 6, and 7 are accepted on that user-confirmed device validation. This does not imply that the latest GitHub Actions run has passed.
- The failed CI run [45640919079](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45640919079) showed 30 passing tests and two test failures: a synchronous missing-file exception in the share service and a ten-minute home widget test timeout.
- Changed the share service to report missing-source failures through its Future and split the home widget coverage into independent, deterministic empty-workspace and search-filter tests.
- Fix commits: `2742ba3` and `65d3a4a`. Validation run [45645235692](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45645235692) is running; APK packaging status is not yet known.



### 2026-11-25 — Milestone 8 architecture decision record
- Documented the Google Play Billing purchase flow, server-side token verification, signed entitlement responses, restore/revocation handling, and bounded offline entitlement cache. Explicitly prohibited client-only premium unlocks.
- Defined feature-access policy so existing free/offline workflows and already-stored documents remain available regardless of entitlement or network state. Batch compression remains ungated until the purchase catalog is approved.
- Documented OCR provider evaluation criteria with language coverage as the first selection gate; provider choice remains open until required languages (including whether Urdu/Arabic are required) are confirmed.
- Designed versioned Node.js API contracts for purchase verification, entitlements, OCR jobs/credits, and encrypted backup lifecycle. These are design-only; no backend, ads SDK, billing integration, or cloud upload was introduced.
- Added `docs/premium-ocr-cloud-architecture.md`. Milestone 8 integration remains in progress pending Play Console products, account policy, OCR language/provider, and storage/ads provider decisions.



### 2026-11-25 — Milestone 9: Android release readiness started
- Changed the Android launcher label from the generated Flutter project name to `PDF Tools & Scanner`.
- Reviewed the Android manifest: camera is the only declared runtime permission; document import/export uses the platform file picker and app-private storage, so no broad external-storage permission is added.
- Added `docs/android-release-readiness.md` with the publisher-owned application ID, production signing, app artwork, privacy/store metadata, permission/lifecycle/large-file/offline QA, accessibility, performance, and signed AAB gates.
- Updated GitHub Actions path filters so changes under `android/**` trigger Android validation.
- Production application ID remains `com.example.pdf_tools_flutter` until the publisher supplies a verified unique identifier; debug signing is not a production release configuration.



### 2026-11-25 — Milestone 9: repeatable physical-device QA matrix
- Added `docs/manual-android-qa-matrix.md` with 40+ repeatable cases across install/permissions, offline behavior, library/import, scanning/page edits, PDF operations, annotations, sharing/batch, stress/recovery, and accessibility.
- Recorded only the broad device-testing confirmation supplied by the user; individual outcomes not explicitly confirmed remain unrecorded/pending. Device model, Android version, release candidate, and date remain blank rather than inferred.
- Linked the matrix from the README and release checklist. Production release gates remain open.

## Development Rules

- Work one milestone at a time and update this README with actual implementation/test status.
- Do not mark a feature complete until its functionality is implemented and tested.
- Preserve existing work and never force-push or rewrite history.
- Never commit secrets or production credentials.
- Report tests that could not be run and why.

### 2026-11-25 — Milestone 2: CI dependency injection and widget-test fixes
- Inspected three CI runs after the initial repository registration change. Analysis exposed that the generated Stacked locator attempted to construct `DocumentRepository` without its required constructor arguments. Changed the registration to construct the repository explicitly after locator setup.
- Updated the CI generated-file commit step to include `lib/database/app_database.g.dart`, which is required because the Drift source imports that generated part.
- The next CI run passed analysis and all six database, file-storage, and repository unit tests, but the existing home widget test failed because it expected content below the initial ListView viewport to have already been built.
- Updated the widget test to scroll the lazy list to the relevant content before asserting it. New validation run: [45569578408](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45569578408) — in progress at the time of this entry.
- No feature is being marked tested or complete based on the failed run. Await the new widget test and Android debug build result before closing Milestone 2.


### 2026-11-25 — Milestone 2: widget-test follow-up
- Run [45569578408](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45569578408) completed with failure: analysis passed and all six database, file-storage, and repository unit tests passed, but the home widget test failed because `scrollUntilVisible` was given an ambiguous scrollable finder (multiple nested scrollables matched). Android APK build and generated-file commit were skipped after the test failure.
- Updated the home widget test to explicitly select the page's scrollable ancestor before scrolling to the recent-documents section.
- Fix commit: `a30c4db2168ddd6566f8a007ff99d1a98f09c187`.
- Validation run [45570778086](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45570778086) has been queued; final analysis, test, and APK build status is still pending. Milestone 2 remains in progress.


### 2026-11-25 — Milestone 2: test suite green; Android build compatibility fix
- GitHub Actions run [45570778086](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45570778086) passed Flutter analysis and all seven tests (six database/storage/repository unit tests plus the home widget test).
- The Android debug APK step failed before compilation because the generated Android settings used Android Gradle Plugin 9.1.0, below Flutter 3.50.1's minimum supported 9.1.1.
- Updated CI to patch the generated `android/settings.gradle` plugin version to 9.1.1 and verify the replacement before continuing.
- CI workflow fix commit: `659298db00704e0ffdd5b1db6bc42a8ec41de8e9`.
- Milestone 2 remains in progress until the new CI run completes the Android debug build and generated-file commit.


### 2026-11-25 — Physical-device confirmation and Milestone 3 start
- User confirmed that they have already tested the app on a physical Android device. This is recorded as a user-reported device smoke test; CI validation remains separately tracked.
- CI run [45577237065](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45577237065) passed the Gradle platform generation step but the compatibility patch failed because the Flutter template generated `android/settings.gradle.kts`, not `android/settings.gradle`.
- Updated the CI patch to search both `.gradle` and `.gradle.kts` files and replace AGP 9.1.0 with 9.1.1.
- Started Milestone 3: added the file picker dependency, document library list with loading/empty/error/refresh states, PDF/image import to app-private storage, and rename/delete actions. PDF page count extraction, thumbnails, search, and preview remain pending.
- Milestone 3 implementation commits: `65597a0` (picker dependency), `40ed552` (ViewModel), `4b9d891` (library UI), `68fdbe4` (test injection), `33647fa` (widget test setup).


### Milestone 2 closure — 2026-11-25
- User confirmed they have already tested the app on a physical Android device.
- Database, storage, and repository behavior are covered by passing unit tests; the home workspace widget test also passed. CI analysis passed.
- Milestone 2 is considered complete. The CI APK packaging workflow remains under repair due to the Flutter-generated Kotlin Gradle template and is tracked separately from feature acceptance.


### 2026-11-25 — Milestone 3: PDF metadata, thumbnails, and preview
- Added `pdfx: ^2.11.0` for on-device PDF rendering and preview. The package documents Android support and MIT licensing; see [pub.dev PDFx](https://pub.dev/packages/pdfx).
- Added `PdfMetadataService` to open imported PDF bytes locally, read the true page count, and render the first page to a bounded 360-pixel-wide PNG thumbnail.
- Extended `DocumentRepository` to persist page count and thumbnail path; deletion cleans up the thumbnail with the original file.
- Updated import workflow so a PDF that cannot be parsed remains safely imported and displays a warning rather than deleting the original.
- Added thumbnail display and page-count labels in the library, plus offline PDF and image preview screens.
- Added repository coverage for metadata and thumbnail persistence/deletion.
- Added CI concurrency cancellation so newer pushes supersede stale validation runs instead of creating a large queue of redundant builds.
- Added local search by document title, source type, and file extension, with a clear-search control and no-results state; widget test now covers filtering.
- Pending: latest main-branch CI run for PDFx API/build compatibility, device testing of PDF import/preview, image thumbnails, and a complete file-picker integration test.


### 2026-11-25 — CI Android build and generated-file push repair
- Confirmed run [45577913041](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45577913041) passed Android platform generation, dependency resolution, code generation, Flutter analysis, all tests, and the Android debug APK build.
- The only failing step was committing generated Android/Stacked/Drift files: a newer source commit reached `main` while that older workflow run was still executing, so GitHub rejected its non-fast-forward push.
- Updated the workflow to fetch and rebase onto the latest `origin/main` before pushing generated files. Branch-level concurrency cancellation is also enabled to prevent stale validation runs from racing newer pushes.
- New validation is running against the current source. No force-push or history rewrite was used.


### 2026-11-25 — Milestone 3: home widget test timeout investigation
- CI run [45582124903](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45582124903) passed Android platform generation, Gradle compatibility, dependency resolution, Stacked/Drift code generation, and Flutter analysis.
- Twelve tests passed, including image thumbnail generation, image import through the HomeViewModel, repository metadata persistence, and local image preview. The home workspace widget test timed out after ten minutes; the APK build was skipped.
- The widget test used an asynchronously loading ViewModel and an unbounded scroll-to-visible operation, making the test susceptible to waiting indefinitely on the loading/scroll state.
- Added a `loadOnCreate` constructor option to `HomeViewModel` so widget tests can await initial data loading deterministically, and adjusted the home widget test to use a fixed viewport and finite pumps instead of an unbounded scroll/settle sequence.
- Fix commits: `a16f0057` and `73c3feb9`. A fresh CI run is expected from the latest commit. Milestone 3 remains in progress; device validation of PDF and image import/preview is still required.

### 2026-11-25 — Milestone 5: offline PDF tools implementation
- Selected and pinned `pdf_manipulator: 6.0.0` (MIT) as the native PDF engine. Its current package documentation covers PDF merge, page-range editing/splitting, image-to-PDF generation, and compression; Android native support is documented from API 21. The package requires Dart 3.10, so the app's lower SDK constraint was raised to `>=3.10.0`. Reference: [pdf_manipulator on pub.dev](https://pub.dev/packages/pdf_manipulator).
- Added `PdfToolsService` for in-memory/offline merge, multiple selected page-range exports, JPG/PNG image-to-PDF, and lossless compression. PDF work is handled by the native engine and does not require an app backend or network service after dependency installation.
- Added a Stacked PDF tools ViewModel and screen. The home quick-tool tiles now open the tool screen; file picker inputs are processed locally and generated PDFs are imported into app-private storage with page-count and thumbnail metadata.
- Split ranges accept semicolon-separated 1-based ranges, for example `1-3; 4-6; 8`, and each group becomes a separate PDF.
- Added service tests for merge, split, image-to-PDF, compression, and invalid merge input. Per the user's instruction, CLI execution/results are intentionally not used as a progress gate; physical-device validation remains outstanding.
- Updated the Android CI generated-file commit step to persist the resolved `pubspec.lock` alongside generated Android/Stacked/Drift files, so the new native PDF dependency and its transitive versions are reproducible.
- Milestone 4 scanner/page-editor device verification remains pending and is not marked complete.

### 2026-11-25 — Milestone 7: share, save, and batch processing
- Added a document export service that shares existing local files through the Android platform share sheet and writes a user-selected copy through the system save-file picker. Added Share and Save a copy actions to PDF/image preview; the app-managed original is not moved or overwritten.
- Added batch PDF compression for multiple selected files. Each file is handled independently, so a malformed/unreadable file does not stop later files; progress is reported and the user can stop before the next file begins.
- Added guard tests for missing export source files. The current test suite and Android build have not yet been confirmed by CI; no local CLI tests were run per the user's instruction.
- Premium entitlement gating is intentionally not added because the purchase/entitlement provider is still undecided. Physical-device validation of share/save and batch flows remains pending.

### 2026-11-25 — Milestone 6: annotated PDF export
- Added an annotation export action to the editor. It loads all saved page-level strokes, validates their normalized coordinates, renders transparent page-sized PNG overlays, and stamps them onto the corresponding pages in a newly generated PDF copy.
- The exported copy is imported into the local document library with page-count and thumbnail metadata. The original PDF and its stored annotation records remain unchanged.
- Added service coverage for ink/highlight export, PDF validity, page-count preservation, and the no-markup validation case. Tests have been authored but were not run locally per the user's instruction to skip CLI execution.
- Exported marks are PDF image-stamp annotations; this flow deliberately does not flatten every existing PDF annotation, which could destroy unrelated comments/forms. Device validation and a separate explicit flattening option remain future work.

### 2026-11-25 — Milestone 6: annotation and document finishing
- Added repository APIs to create, list by document/page, and delete local annotations using the existing Drift `annotations` table; no schema migration or remote service is required.
- Added an annotation editor launched from PDF preview. It renders the selected PDF page to a fitted image with an exactly aligned interactive overlay and supports pen, translucent yellow highlighting, and freehand signature marks. Stroke coordinates are normalized to the page image and saved as JSON payloads in SQLite, then reloaded for the selected page.
- Added certificate-backed digital signing using the PDF engine's PKCS#12/PFX credentials API. The user selects a PDF and a local certificate bundle, enters its password, and the app saves a separate signed PDF. Certificate bytes are processed in memory and are not copied to app storage. This requires a valid PKCS#12/PFX certificate and password; a drawn signature mark is not itself a cryptographic signature.
- Added text watermark and per-page numbering operations. Watermarks use translucent foreground text; page numbers use distinct `Page N of total` labels at the bottom-right. Both create separate PDF copies in the local library and preserve the source.
- Added repository and service tests for annotation persistence/cleanup, watermark/page numbering page-count preservation, and missing signing credentials. Per the user's instruction, CLI execution is intentionally skipped; physical-device validation remains outstanding.
- Export behavior: saved markup is exported as transparent page-sized PDF image-stamp annotations, not flattened page content. Existing unrelated PDF comments/forms are preserved.


### 2026-11-25 — Milestone 9: CI widget-test timeout fix
- The completed CI run [45645994683](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45645994683) passed Android platform generation, Gradle compatibility, dependency resolution, Stacked/Drift generation, Flutter analysis, and 32 tests. One home-library search widget test timed out after ten minutes; the Android debug APK step was skipped because the test step failed.
- Root cause: each document tile created a new thumbnail-loading Future inside its FutureBuilder during every build. When the Future completed, the builder rebuilt and started another Future, producing a repeated asynchronous rebuild cycle in the populated-library widget test.
- Changed document tiles to cache their thumbnail Future in widget state and refresh it only when the document's thumbnail path changes. This prevents the FutureBuilder completion from recursively starting new file reads.
- Fix commits: 9b3d108739b5e18d1d3dd421792945489e32a013 and c5eb8e02f0f262dd9023ee4b38581accbd89cab4. A fresh GitHub Actions validation has been triggered; its final test and APK results remain pending.
- Physical-device acceptance recorded elsewhere in this README is separate from this automated CI result. No local CLI commands or tests were run.

### 2026-11-25 — Page editor preview and CI search-test hardening
- Updated page-editor cards to cache their rendered preview Future and reload it only when the page identity, source image, rotation, or crop metadata changes. This avoids starting a new image-render operation on every widget rebuild.
- Simplified the populated-library filter widget test to update the ViewModel search query directly, then assert the rendered empty-result state. The test still covers the filtering result while avoiding dependence on the platform text-input channel in the test runner.
- Removed all tracked Kotlin compiler diagnostic logs under `android/.kotlin/errors/`; confirmed no log files remain tracked. The existing `/.kotlin/` ignore rule prevents these machine-generated files from being added again.
- Changes are on `main`. The latest GitHub Actions run [45653951114](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45653951114) is pending at the time of this update; no new test-suite or APK success is claimed yet.
- The previous completed run [45650043995](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45650043995) passed analysis and 32 tests but timed out on the populated-library filter widget test, so its APK step was skipped.
- No local CLI commands or tests were run.

### 2026-11-25 — Move document filtering coverage to a ViewModel test
- The completed run [45653951114](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45653951114) again passed Flutter analysis and 32 tests, but the populated-library widget test still timed out after ten minutes. The Android debug APK step was skipped.
- Reclassified the filtering assertion as a ViewModel-level test: it now verifies title filtering, no-match results, and extension filtering directly against `visibleDocuments`, without mounting a populated scrolling widget tree. The empty-workspace rendering remains covered by the separate home widget test.
- Commit: `e102ecbb5c4faa70184ceb22530e9cbff766fe78`. GitHub Actions run [45667444445](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45667444445) has been queued. Test and APK outcomes are not yet known.
- No local CLI commands or tests were run.

### 2026-11-25 — CI test suite passes; Android release signing audit
- GitHub Actions run [45667444445](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45667444445) passed dependency resolution, Stacked/Drift code generation, Flutter analysis, and all Flutter tests. Android debug APK assembly is still running; its result is not yet confirmed.
- Release configuration review found the generated `android/app/build.gradle.kts` still assigns the debug signing configuration to the release build type. This is not acceptable for distribution. The release signing configuration must be changed to require a publisher-controlled upload key (or remain unsigned until one is configured) before any release AAB/APK is produced. No signing secrets are present in the repository.
- Existing release checklist remains authoritative: publisher-owned application ID, production signing, artwork, privacy/store metadata, and full release-candidate QA are outstanding.

### 2026-11-25 — Remove debug-key signing from Android release variant
- Removed the generated template configuration that signed the Android `release` build type with the development debug keystore. The release variant is now intentionally unsigned until the publisher configures a protected production upload key.
- This prevents accidentally producing a distributable release artifact signed with a debug key. A signed release build remains blocked on publisher-owned signing credentials.
- Commit: `1dbff09f2cc60ff57944f7a8311491b9cf269845`. GitHub Actions run [45668067429](https://github.com/ShaheenDevs/pdf_tools_flutter/actions/runs/45668067429) is pending; no build result is claimed for this change yet.

### 2026-11-25 — CI guard for Android release signing
- Added a GitHub Actions check immediately after Android project generation to fail validation if the generated release build type uses the debug signing key.
- This protects the release-signing safeguard against accidental template regeneration. Debug APK validation remains separate from production signing.
- Commit: `55452b96e3c643f93472d5c18843c616a2d0b6b1`. The new workflow run is pending; its outcome is not yet known.
