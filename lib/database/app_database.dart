import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get sourceType => text().withDefault(const Constant('imported'))();
}

class DocumentPages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageIndex => integer()();
  TextColumn get sourceImagePath => text().nullable()();
  IntColumn get rotation => integer().withDefault(const Constant(0))();
  TextColumn get cropData => text().nullable()();
  @override
  List<Set<Column<Object>>> get uniqueKeys => [{documentId, pageIndex}];
}

class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageIndex => integer()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [Documents, DocumentPages, Annotations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Add forward-only migrations here when the schema changes.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final Directory support = await getApplicationSupportDirectory();
  final Directory dbDirectory = Directory(p.join(support.path, 'database'));
  await dbDirectory.create(recursive: true);
  return NativeDatabase.createInBackground(
    File(p.join(dbDirectory.path, 'pdf_tools.sqlite')),
  );
});
