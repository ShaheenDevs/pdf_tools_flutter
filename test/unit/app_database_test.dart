import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting());
  tearDown(() => database.close());

  test('stores documents, pages, and annotations', () async {
    final now = DateTime.utc(2026, 1, 1);
    final id = await database
        .into(database.documents)
        .insert(
          DocumentsCompanion.insert(
            title: 'Sample scan',
            filePath: 'documents/sample.pdf',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.documentPages)
        .insert(
          DocumentPagesCompanion.insert(
            documentId: id,
            pageIndex: 0,
            sourceImagePath: const Value('images/page-1.jpg'),
          ),
        );
    await database
        .into(database.annotations)
        .insert(
          AnnotationsCompanion.insert(
            documentId: id,
            pageIndex: 0,
            type: 'highlight',
            payload: '{"color":"yellow"}',
            createdAt: now,
            updatedAt: now,
          ),
        );
    expect(await database.select(database.documents).get(), hasLength(1));
    expect(await database.select(database.documentPages).get(), hasLength(1));
    expect(await database.select(database.annotations).get(), hasLength(1));
  });

  test('cascades document deletion to pages and annotations', () async {
    final now = DateTime.utc(2026, 1, 1);
    final id = await database
        .into(database.documents)
        .insert(
          DocumentsCompanion.insert(
            title: 'Delete me',
            filePath: 'documents/delete.pdf',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.documentPages)
        .insert(DocumentPagesCompanion.insert(documentId: id, pageIndex: 0));
    await database
        .into(database.annotations)
        .insert(
          AnnotationsCompanion.insert(
            documentId: id,
            pageIndex: 0,
            type: 'note',
            payload: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await (database.delete(
      database.documents,
    )..where((row) => row.id.equals(id))).go();
    expect(await database.select(database.documentPages).get(), isEmpty);
    expect(await database.select(database.annotations).get(), isEmpty);
  });
}
