# Manual Android QA Matrix

This checklist is the repeatable physical-device test record for release candidates. It complements GitHub Actions; it does not replace automated tests. Record device model, Android version, app version/commit, date, and tester for each release candidate.

**Acceptance evidence:** The user has confirmed physical-device testing for scanner/page editing, PDF tools, annotation/signature/finishing, and share/batch workflows. Detailed per-case outcomes below are intentionally left open until a release-candidate test pass is recorded.

## Test record

| Field | Value |
|---|---|
| Device model | Not recorded |
| Android version | Not recorded |
| App version / commit | Not recorded |
| Test date | Not recorded |
| Tester | User-confirmed device testing |
| Candidate type | Debug build; production release candidate not yet prepared |

## A. Install, launch, and permissions

| ID | Scenario | Expected result | Status |
|---|---|---|---|
| A-01 | Fresh install and first launch | App opens to the document workspace without account/network setup | User confirms app launch on device |
| A-02 | Grant camera permission and scan | Native scanner opens and returns to the app | User confirms scanner workflow tested |
| A-03 | Deny camera permission once | App explains scanning needs camera access; import/library remain usable | Not separately recorded |
| A-04 | Permanently deny camera permission | App offers a route to Android Settings; no crash or permission loop | Not separately recorded |
| A-05 | Relaunch after force-stop/reboot | Local library and saved documents remain available | Not separately recorded |
| A-06 | Airplane mode | Core local library, preview, editing, PDF tools and export remain usable | Not separately recorded |

## B. Import and document library

| ID | Scenario | Expected result | Status |
|---|---|---|---|
| B-01 | Import a valid PDF | PDF is copied into app-private storage and appears in the library | User confirms PDF import tested |
| B-02 | Import JPG/PNG | Image is copied, thumbnail is generated, preview opens | User confirms image import/preview tested |
| B-03 | Search by title/extension | Results filter correctly; empty state appears when no match | Automated widget coverage; device outcome not separately recorded |
| B-04 | Rename a document | New title persists after navigating away/relaunching | Not separately recorded |
| B-05 | Delete a document | Confirmation is required; document and managed files are removed | Not separately recorded |
| B-06 | Import unsupported/invalid file | Clear error; no partial library entry or crash | Automated validation exists; device outcome not separately recorded |

## C. Scan and page editing

| ID | Scenario | Expected result | Status |
|---|---|---|---|
| C-01 | Scan one page | One-page PDF and source image are saved locally | User confirms scanner workflow tested |
| C-02 | Scan multiple pages | PDF page order matches scanner order and all source images are retained | User confirms scanner workflow tested |
| C-03 | Rotate page 90° repeatedly | Rotation persists and regenerated PDF reflects orientation | User confirms page-editor workflow tested |
| C-04 | Crop page margins | Crop persists and regenerated PDF reflects crop | User confirms page-editor workflow tested |
| C-05 | Reorder pages | PDF order and page metadata match the displayed order | User confirms page-editor workflow tested |
| C-06 | Delete a page | Page is removed from PDF and metadata; at least one page remains | User confirms page-editor workflow tested |
| C-07 | Cancel edits / simulate save failure | Previous PDF remains readable and unchanged | Not separately recorded |

## D. PDF tools and finishing

| ID | Scenario | Expected result | Status |
|---|---|---|---|
| D-01 | Merge two or more PDFs | New PDF contains pages in selected order; sources remain unchanged | User confirms PDF tools tested |
| D-02 | Split a PDF by page ranges | Each requested range is exported as its own PDF | User confirms PDF tools tested |
| D-03 | Convert multiple images to PDF | Generated PDF includes selected images in order | User confirms PDF tools tested |
| D-04 | Compress a PDF | New copy is generated; source remains unchanged; size result is shown | User confirms PDF tools tested |
| D-05 | Add watermark/page numbers | New PDF opens and has the expected overlay on each page | User confirms finishing tools tested |
| D-06 | Sign with valid PKCS#12/PFX | Signed output is produced; certificate bytes/password are not persisted in app storage | User confirms signing workflow tested |
| D-07 | Sign with invalid password/certificate | Clear failure; original document remains unchanged | Not separately recorded |
| D-08 | Merge/split/compress malformed or encrypted PDF | Operation fails safely with a useful message; no corrupt library output | Not separately recorded |

## E. Annotation, sharing, and batch processing

| ID | Scenario | Expected result | Status |
|---|---|---|---|
| E-01 | Add pen/highlight/signature strokes | Markup persists when reopening the annotation editor | User confirms annotation workflow tested |
| E-02 | Export annotated copy | Separate PDF appears in library; original PDF remains unchanged | User confirms annotation export tested |
| E-03 | Clear page markups | Only selected page's app-side markups are removed | Not separately recorded |
| E-04 | Share PDF/image | Android system share sheet opens with the selected file | User confirms share workflow tested |
| E-05 | Save a copy | Android save-file UI writes a readable copy to the chosen destination | User confirms save/export workflow tested |
| E-06 | Batch compress mixed valid/invalid PDFs | Valid files complete, failures are isolated, progress remains accurate | User confirms batch workflow tested |
| E-07 | Stop batch during processing | Current file completes; no later files start | User confirms batch workflow tested |

## F. Stress, recovery, and accessibility (release gate)

| ID | Scenario | Expected result | Status |
|---|---|---|---|
| F-01 | Import a large PDF and high-resolution image | App remains responsive or shows a controlled error; no partial/corrupt entry | Pending |
| F-02 | Device storage nearly full during import/export | Clear error; original and existing library data remain safe | Pending |
| F-03 | Interrupt app during file write | Temporary files are recoverable/cleanable; library does not point to incomplete final files | Pending |
| F-04 | Rotate device/background app during long operation | No lost/corrupted source document; UI returns to a stable state | Pending |
| F-05 | TalkBack navigation and labels | All primary controls are discoverable and actionable | Pending |
| F-06 | Large system text/font scaling | Primary actions and document controls remain usable | Pending |
| F-07 | Low/mid-range device performance | Scanning, preview, and PDF operations complete within acceptable product targets | Pending |

## Release decision

Do not mark the Android release ready until:
- GitHub Actions analysis, tests, and debug APK build pass on the release commit.
- A release candidate has been installed from a clean state and the relevant matrix cases have been rerun.
- Production application ID, release signing, store assets, privacy policy, and Play Console declarations are complete.
- All high-severity data-loss, permission, and export failures are resolved.
