// lib/src/db/app_db.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_db.g.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 0, max: 250)();
  TextColumn get content => text().nullable()(); // Quill delta JSON
  IntColumn get parentId => integer().nullable().references(Notes, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isExpanded => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class MediaItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().customConstraint('NOT NULL REFERENCES notes(id) ON DELETE CASCADE')();
  TextColumn get type => text().withLength(min: 0, max: 20)(); // image/video
  TextColumn get path => text()(); // local file path or URL
  IntColumn get position => integer().withDefault(const Constant(0))();
}

class Topics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get parentId => integer().nullable().references(Topics, #id)();
  IntColumn get order => integer().withDefault(const Constant(0))();
}

class NoteTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().customConstraint('NOT NULL REFERENCES notes(id) ON DELETE CASCADE')();
  IntColumn get topicId => integer().customConstraint('NOT NULL REFERENCES topics(id) ON DELETE CASCADE')();
}

class Steps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().customConstraint('NOT NULL REFERENCES notes(id) ON DELETE CASCADE')();
  IntColumn get stepOrder => integer().withDefault(const Constant(0))();
  TextColumn get title => text().withLength(min: 0, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get duration => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
}

/// The App Database
@DriftDatabase(tables: [Notes, MediaItems, Topics, NoteTopics, Steps])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(p.join(docs.path, 'martial_notes.sqlite'));
      return NativeDatabase(file, logStatements: false);
    });
  }

  // create called from main to ensure path resolution is async
  static Future<AppDb> create() async {
    final db = AppDb();

    // seed sample data if empty
    final topicCount = await db.select(db.topics).get();
    if (topicCount.isEmpty) {
      await db.seedSampleData();
    }

    return db;
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add the new columns for hierarchical notes
        await m.addColumn(notes, notes.parentId);
        await m.addColumn(notes, notes.sortOrder);  
        await m.addColumn(notes, notes.isExpanded);
      }
      // For now, recreate all tables when upgrading to version 3
      if (from < 3) {
        await m.createAll();
      }
    },
  );

  Future<void> seedSampleData() async {
    // simple seed
    final idStyle = await into(topics).insert(TopicsCompanion.insert(name: 'Style', parentId: Value(null)));
    await into(topics).insert(TopicsCompanion.insert(name: 'Krav Maga', parentId: Value(idStyle)));
    final idStriking = await into(topics).insert(TopicsCompanion.insert(name: 'Striking', parentId: Value(null)));
    final noteId = await into(notes).insert(NotesCompanion.insert(title: 'Front Kick', content: Value('')));
    await into(noteTopics).insert(NoteTopicsCompanion.insert(noteId: noteId, topicId: idStriking));
  }

  // Basic queries
  Stream<List<Topic>> watchAllTopics() {
    return (select(topics)..orderBy([(t) => OrderingTerm(expression: t.order)])).watch();
  }

  Future<List<Topic>> getAllTopicsOnce() => (select(topics)..orderBy([(t) => OrderingTerm(expression: t.order)])).get();

  Stream<List<Note>> watchNotesForTopic(int? topicId) {
    if (topicId == null) {
      // unsorted: notes without topics
      final q = select(notes).watch();
      return q.asyncMap((allNotes) async {
        final withTopics = await (select(noteTopics)).get();
        final noteIdsWithTopics = withTopics.map((e) => e.noteId).toSet();
        return allNotes.where((n) => !noteIdsWithTopics.contains(n.id)).toList();
      }).asBroadcastStream();
    } else {
      final join = select(notes).join([
        innerJoin(noteTopics, noteTopics.noteId.equalsExp(notes.id) & noteTopics.topicId.equals(topicId)),
      ]);
      return join.watch().map((rows) => rows.map((r) => r.readTable(notes)).toList());
    }
  }

  Future<int> createNote(String title, String? content, {List<int>? topicIds, int? parentId}) async {
    // Get the max sort order for siblings
    int sortOrder = 0;
    if (parentId != null) {
      final siblings = await (select(notes)..where((n) => n.parentId.equals(parentId))).get();
      sortOrder = siblings.length;
    } else {
      final topLevel = await (select(notes)..where((n) => n.parentId.isNull())).get();
      sortOrder = topLevel.length;
    }
    
    final noteId = await into(notes).insert(NotesCompanion.insert(
      title: title, 
      content: Value(content),
      parentId: Value(parentId),
      sortOrder: Value(sortOrder),
    ));
    
    if (topicIds != null) {
      for (final t in topicIds) {
        await into(noteTopics).insert(NoteTopicsCompanion.insert(noteId: noteId, topicId: t));
      }
    }
    return noteId;
  }

  // Get hierarchical notes as a tree structure
  Stream<List<Note>> watchHierarchicalNotes() {
    return (select(notes)..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])).watch();
  }

  Future<List<Note>> getChildNotes(int parentId) async {
    return await (select(notes)
      ..where((n) => n.parentId.equals(parentId))
      ..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])
    ).get();
  }

  Future<List<Note>> getRootNotes() async {
    return await (select(notes)
      ..where((n) => n.parentId.isNull())
      ..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])
    ).get();
  }

  Future<void> moveNote(int noteId, int? newParentId, int newSortOrder) async {
    await (update(notes)..where((n) => n.id.equals(noteId))).write(NotesCompanion(
      parentId: Value(newParentId),
      sortOrder: Value(newSortOrder),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> toggleNoteExpanded(int noteId, bool isExpanded) async {
    await (update(notes)..where((n) => n.id.equals(noteId))).write(NotesCompanion(
      isExpanded: Value(isExpanded),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateNoteContent(int id, String? content, {String? title}) async {
    await (update(notes)..where((tbl) => tbl.id.equals(id))).write(NotesCompanion(content: Value(content), title: title != null ? Value(title) : Value.absent(), updatedAt: Value(DateTime.now())));
  }

  Future<void> deleteNote(int id) async {
    await (delete(notes)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> addMedia(int noteId, String type, String path, {int position = 0}) async {
    await into(mediaItems).insert(MediaItemsCompanion.insert(noteId: noteId, type: type, path: path, position: Value(position)));
  }

  Future<List<MediaItem>> getMediaForNoteOnce(int noteId) => (select(mediaItems)..where((m) => m.noteId.equals(noteId))..orderBy([(m) => OrderingTerm(expression: m.position)])).get();

  // Steps methods
  Future<List<Step>> getStepsForNote(int noteId) => (select(steps)..where((s) => s.noteId.equals(noteId))..orderBy([(s) => OrderingTerm(expression: s.stepOrder)])).get();

  Future<int> createStep(int noteId, String title, {String? description, String? imageUrl, String? duration, String? notes}) async {
    final maxOrder = await (selectOnly(steps)..addColumns([steps.stepOrder.max()])..where(steps.noteId.equals(noteId))).getSingle();
    final nextOrder = (maxOrder.read(steps.stepOrder.max()) ?? 0) + 1;
    
    return await into(steps).insert(StepsCompanion.insert(
      noteId: noteId,
      stepOrder: Value(nextOrder),
      title: title,
      description: Value(description),
      imageUrl: Value(imageUrl),
      duration: Value(duration),
      notes: Value(notes),
    ));
  }

  Future<void> updateStep(int stepId, {String? title, String? description, String? imageUrl, String? duration, String? notes}) async {
    await (update(steps)..where((s) => s.id.equals(stepId))).write(StepsCompanion(
      title: title != null ? Value(title) : Value.absent(),
      description: Value(description),
      imageUrl: Value(imageUrl),
      duration: Value(duration),
      notes: Value(notes),
    ));
  }

  Future<void> deleteStep(int stepId) async {
    await (delete(steps)..where((s) => s.id.equals(stepId))).go();
  }

  Future<void> reorderSteps(int noteId, List<int> stepIds) async {
    await transaction(() async {
      for (int i = 0; i < stepIds.length; i++) {
        await (update(steps)..where((s) => s.id.equals(stepIds[i]))).write(StepsCompanion(
          stepOrder: Value(i),
        ));
      }
    });
  }
}
