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
| Camera document scanning | ☐ | Capture one or more pages, handle camera permission, and create a local document |
| Crop and rotate pages | ☐ | Crop page boundaries and rotate individual pages |
| Reorder pages | ☐ | Change page sequence and persist the resulting PDF |
| Delete pages | ☐ | Remove selected pages with confirmation |
| Merge PDFs | ☐ | Select multiple local PDFs and combine them in chosen order |
| Split PDFs | ☐ | Export selected page ranges or individual pages as separate PDFs |
| Basic PDF compression | ☐ | Provide a local compression workflow where supported |
| Image to PDF | ☐ | Import local images and generate a PDF |
| Local annotation and highlighting | ☐ | Add, edit, and persist annotations/highlights locally |
| Share and export | ☐ | Export generated files through Android share/save flows |
| Document library | ☐ | Browse, search, rename, and delete locally managed documents |

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
| PDF preview | ☐ | View document pages and navigate the PDF |
| Document metadata | ☐ | Persist title, file path, page count, size, timestamps, and related page data |

## C. Development Progress

| Area / feature | Status | Flutter | Backend | Testing |
|---|---|---|---|---|
| Repository analysis | [~] | Reference and target repositories inspected | Reference inspected; no target backend | Not applicable |
| Project setup | [~] | Flutter source foundation and Stacked shell merged to main; CI generates Android platform files and Stacked code | N/A | Not run: Flutter SDK unavailable |
| Local database and file storage | ☐ | Pending | N/A | Pending |
| Document library | ☐ | Pending | N/A | Pending |
| Camera scanning and page editing | ☐ | Pending | N/A | Pending |
| Merge, split, and image-to-PDF | ☐ | Pending | N/A | Pending |
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
- [~] Configure dependencies, app entry point, Stacked locator, and route annotations; CI generation succeeds, but analysis currently fails on a leftover default Flutter counter test.
- [x] Add a basic app shell, reusable theme, and initial home workspace.
- [~] Add a home-screen widget test and setup instructions; CI reached analysis but tests/build were skipped after analysis errors.

### Milestone 2 — Local database and file storage
- [ ] Add Drift/SQLite database and migrations.
- [ ] Implement document, page, and annotation metadata models/tables.
- [ ] Implement app-private file storage and safe file lifecycle operations.
- [ ] Add repository tests and database migration tests.

### Milestone 3 — Document library and import
- [ ] Build the document library, empty/loading/error states, search, rename, and delete.
- [ ] Import existing PDFs and images from Android storage/document picker.
- [ ] Generate and persist thumbnails and metadata.
- [ ] Test import, reopen, rename, and delete flows.

### Milestone 4 — Camera scanning and page editing
- [ ] Implement camera capture and multi-page scan sessions.
- [ ] Add crop and rotate.
- [ ] Add page reorder and delete.
- [ ] Generate a valid PDF from scanned pages and test on real Android devices.

### Milestone 5 — PDF tools
- [ ] Implement merge and split.
- [ ] Implement image-to-PDF conversion.
- [ ] Implement basic compression and measure output size/quality.
- [ ] Validate malformed, encrypted, large, and unsupported PDFs with clear errors.

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
The repository now contains the initial Dart/Flutter source foundation. Android platform scaffolding has not yet been generated because the Flutter SDK is unavailable in the development environment. The GitHub Actions workflow `.github/workflows/flutter-android-ci.yml` generates Android platform files, resolves dependencies, runs Stacked code generation, analyzes the project, runs tests, builds a debug APK, and commits generated Android/Stacked files to `main` when validation succeeds. To run locally, use:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Run code generation only after the generated Stacked and Drift dependencies/configuration have been added.

## I. Known Issues and Decisions

- [ ] Fix the leftover default `test/widget_test.dart` counter test, which references a non-existent `MyApp` and an unavailable `material_ui` package; then rerun CI.
- [ ] After CI succeeds, verify generated Android and Stacked files are committed to `main`.
- [ ] PDF engine and camera/scanning package selection must be validated for Android support, licensing, maintenance, and required edit operations.
- [ ] Premium purchase provider and entitlement verification are not yet selected.
- [ ] OCR provider, credit model, and privacy policy are not yet selected.
- [ ] Cloud backup storage and optional backend deployment are not yet designed.
- [ ] Minimum Android SDK and supported Android version range will be confirmed during setup.
- [ ] Digital signature scope (visual signature placement versus certificate-based cryptographic signing) must be explicitly defined before implementation.

## J. Development History

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
- GitHub Actions runs `45473596826` and `45473633399` both failed at `flutter analyze`. Android platform generation, dependency resolution, and Stacked code generation succeeded; widget tests and APK build were skipped. The failures include a leftover Flutter template counter test (`test/widget_test.dart`) referencing `MyApp` and `material_ui`, which does not exist in this project.
- Remaining: remove the unused template test, rerun CI on `main`, and confirm generated Android/Stacked files are committed before closing Milestone 1.

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
