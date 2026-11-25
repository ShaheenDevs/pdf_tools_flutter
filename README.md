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
| Camera document scanning | [~] | Multi-page native scanner with local PDF/page-image persistence; device verification pending |
| Crop and rotate pages | [~] | Persist normalized crop margins and 90° rotations; regenerate the scanned PDF |
| Reorder pages | [~] | Reorder scanned pages and rebuild the PDF in the selected order |
| Delete pages | [~] | Delete a scanned page with confirmation, keeping at least one page |
| Merge PDFs | [~] | Merge multiple local PDFs in picker order; save a new library PDF |
| Split PDFs | [~] | Export semicolon-separated page ranges as separate local PDFs |
| Basic PDF compression | [~] | Lossless local PDF optimization; save a separate copy and report size change |
| Image to PDF | [~] | Convert multiple local JPG/PNG images into one PDF |
| Local annotation and highlighting | ☐ | Add, edit, and persist annotations/highlights locally |
| Share and export | ☐ | Export generated files through Android share/save flows |
| Document library | ☒ | Browse, import, search, preview, rename, and delete locally managed PDF/image documents; user confirmed physical-device validation |

### Premium features

| Feature | Status | Scope |
|---|---|---|
| Batch processing | ☐ | Apply supported operations to multiple documents |
| Advanced compression | ☐ | Offer additional compression profiles and controls |
| OCR credits | ☐ | Future OCR integration; cloud/API dependency and credit policy to be designed |
| Cloud backup | ☐ | Future optional Node.js API and remote storage integration |
| Premium templates | ☐ | Additional scan/export templates |
| Remove ads | ☐ | Premium entitlement controlling ad presentation |

### Additional document tools

| Feature | Status | Scope |
|---|---|---|
| Digital signature | ☐ | Create/import a signature and place it on PDF pages |
| Watermark | ☐ | Add text or image watermarks to selected pages |
| Page numbers | ☐ | Configure and apply page numbering |
| PDF preview | ☒ | Offline PDF page navigation and zoomable local image preview |
| Document metadata | ☒ | Persist title, file path, page count, size, timestamps, and generated PDF/image preview thumbnails |

## C. Development Progress

| Area / feature | Status | Flutter | Backend | Testing |
|---|---|---|---|---|
| Repository analysis | [~] | Reference and target repositories inspected | Reference inspected; no target backend | Not applicable |
| Project setup | ☒ | Flutter app, Android scaffolding, Stacked shell, and generated files are on main | N/A | User confirms they have tested the app on a physical Android device |
| Local database and file storage | ☒ | Drift schema, SQLite connection, app-private atomic file storage, Stacked registrations, and repository operations implemented; generated Drift code is present on main | N/A | Analysis and all seven tests passed in CI; user confirms physical-device testing |
| Document library | ☒ | PDF/image import, searchable local list, rename/delete, PDF page counts, thumbnails, offline PDF/image preview | N/A | User confirmed PDF/image import and preview were run and tested on a physical Android device; automated tests are present, with CI tracked separately |
| Camera scanning and page editing | [~] | Native multi-page scanning, crop/rotate, reorder/delete, PDF regeneration for scanned documents | N/A | Repository and image/PDF service tests added; physical-device validation pending |
| Merge, split, image-to-PDF, and compression | [~] | Offline PDF operations screen, service, and local-library output persistence | N/A | Automated service tests authored; CLI execution intentionally skipped; physical-device verification pending |
| Compression and annotations | ☐ | Pending | N/A | Pending |
| Signature, watermark, and page numbers | ☐ | Pending | N/A | Pending |
| Share and export | ☐ | Pending | N/A | Pending |
| Premium entitlements and ads | ☐ | Pending | Optional future service | Pending |
| OCR and cloud backup | ☐ | Pending | Optional future Node.js service | Pending |
| Release preparation | ☐ | Pending | N/A | Pending |

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
- [~] Integrate the native multi-page document scanner; copy scan PDF and source page images into app-private storage and register page records in Drift. Physical-device verification pending.
- [x] Add post-capture crop margins and persisted 90° page rotation; render edits from original source images.
- [x] Add page reorder and confirmed deletion; prevent deleting the final remaining page.
- [x] Regenerate a multi-page PDF and first-page thumbnail from the edited source images. Save new PDF/thumbnail and page metadata transactionally before cleaning up superseded files.
- [x] Add service tests for crop/rotation/PDF generation and repository tests for reorder/delete persistence. Physical-device verification of the complete scanner/editor flow remains pending.

### Milestone 5 — PDF tools
- [~] Implement offline merge and range-based split; generated files are saved as separate library documents.
- [~] Implement multi-image JPG/PNG to PDF conversion.
- [~] Implement lossless PDF compression and report the resulting size change.
- [~] Map password-protected and corrupted PDF errors to clear user messages; physical-device validation for malformed, encrypted, large, and unsupported inputs remains pending.

### Milestone 6 — Annotation and document finishing
- [ ] Implement local annotation and highlighting.
- [ ] Implement digital signature placement.
- [ ] Implement watermark and page numbers.
- [ ] Verify that edits persist after closing and reopening documents.

### Milestone 7 — Export and batch workflows
- [ ] Implement share/export and Android save destinations.
- [ ] Implement premium batch processing.
- [ ] Add operation progress, cancellation where safe, and partial-failure handling.
- [ ] Test output integrity and temporary-file cleanup.

### Milestone 8 — Premium, OCR, and optional cloud roadmap
- [ ] Define premium entitlement and purchase verification strategy.
- [ ] Add premium templates and remove-ads entitlement.
- [ ] Evaluate OCR provider, credit accounting, privacy, and network requirements.
- [ ] Design optional Node.js APIs for account, backup metadata, upload/download, and OCR jobs.
- [ ] Keep local functionality available when these services are unavailable.

### Milestone 9 — QA and release
- [ ] Run Flutter analyze and automated tests.
- [ ] Test Android permissions, lifecycle, low-storage, large-file, and offline scenarios.
- [ ] Test export/share on supported Android versions.
- [ ] Review performance, accessibility, app size, privacy disclosures, and release configuration.
- [ ] Document release steps and known limitations.

## F. Backend and API Documentation

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

- [ ] CI test/build follow-up is tracked separately and is not the feature acceptance gate; physical-device validation was confirmed by the user.
- [x] Generated Android and Stacked files are present on `main`.
- [x] PDF engine selected: PDFx for offline rendering and page navigation; Android CI and device validation for the newly added import/preview flow remain pending.
- [x] Scanner package selected for Milestone 4: `cunning_document_scanner` (MIT; Android/iOS; multi-page capture and automatic crop; Android API 24 minimum in current 3.x docs).
- [ ] Premium purchase provider and entitlement verification are not yet selected.
- [ ] OCR provider, credit model, and privacy policy are not yet selected.
- [ ] Cloud backup storage and optional backend deployment are not yet designed.
- [ ] Minimum Android SDK and supported Android version range will be confirmed during setup.
- [ ] Digital signature scope (visual signature placement versus certificate-based cryptographic signing) must be explicitly defined before implementation.

## J. Development History

### 2026-11-25 — Milestone 4: page editor and PDF regeneration
- Added a Stacked page editor for scanned documents with per-page preview, 90-degree rotation, adjustable crop margins, drag-and-drop reorder, and confirmed deletion (the last remaining page cannot be deleted).
- Added local rendering with the `image` package and PDF reconstruction with `pdf` 3.13.1. The editor rebuilds the PDF and thumbnail from original page images so edits remain reversible at the source-image level.
- Repository persistence writes replacement PDF/thumbnail files, updates page metadata/order and document metadata in a Drift transaction, then removes superseded files. Added unit coverage for crop, rotation, PDF generation, page order and deletion.
- User device validation of scanner and page editor is still pending; CI is a separate quality check.

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
- Tests: pending CI execution; Drift generated code is produced by the workflow. Local Flutter/Dart SDK is unavailable in this development environment.
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
