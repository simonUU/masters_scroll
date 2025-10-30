// lib/src/db/app_db.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_db.g.dart';

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 0, max: 250)();
  TextColumn get content => text().nullable()(); // Quill delta JSON
  TextColumn get parentId => text().nullable().references(Notes, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isExpanded => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().customConstraint('NOT NULL REFERENCES notes(id) ON DELETE CASCADE')();
  TextColumn get type => text().withLength(min: 0, max: 20)(); // image/video
  TextColumn get path => text()(); // local file path or URL
  IntColumn get position => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Topics extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get parentId => text().nullable().references(Topics, #id)();
  IntColumn get order => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class NoteTopics extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().customConstraint('NOT NULL REFERENCES notes(id) ON DELETE CASCADE')();
  TextColumn get topicId => text().customConstraint('NOT NULL REFERENCES topics(id) ON DELETE CASCADE')();
  
  @override
  Set<Column> get primaryKey => {id};
}

class Steps extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().customConstraint('NOT NULL REFERENCES notes(id) ON DELETE CASCADE')();
  IntColumn get stepOrder => integer()();
  TextColumn get title => text().withLength(min: 1, max: 250)();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get duration => text().nullable()(); // stored as string for flexibility
  TextColumn get notes => text().nullable()(); // additional notes for step
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// The App Database
@DriftDatabase(tables: [Notes, MediaItems, Topics, NoteTopics, Steps])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());
  
  // Constructor for testing
  AppDb.forTesting(QueryExecutor executor) : super(executor);

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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Seed with sample data for new installations
      await seedSampleData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // For development: recreate all tables with new UUID schema
      if (from < 4) {
        // Drop existing tables manually
        await customStatement('DROP TABLE IF EXISTS note_topics');
        await customStatement('DROP TABLE IF EXISTS steps');
        await customStatement('DROP TABLE IF EXISTS media_items');
        await customStatement('DROP TABLE IF EXISTS notes');
        await customStatement('DROP TABLE IF EXISTS topics');
        
        // Recreate all tables with new schema
        await m.createAll();
        
        // Seed with sample data
        await seedSampleData();
      }
    },
  );  Future<void> seedSampleData() async {
    const uuid = Uuid();
    
    // simple seed with UUIDs
    final styleId = uuid.v4();
    final strikingId = uuid.v4();
    final noteId = uuid.v4();
    
    await into(topics).insert(TopicsCompanion.insert(id: styleId, name: 'Style', parentId: Value(null)));
    await into(topics).insert(TopicsCompanion.insert(id: uuid.v4(), name: 'Krav Maga', parentId: Value(styleId)));
    await into(topics).insert(TopicsCompanion.insert(id: strikingId, name: 'Striking', parentId: Value(null)));
    await into(notes).insert(NotesCompanion.insert(id: noteId, title: 'Front Kick', content: Value('')));
    await into(noteTopics).insert(NoteTopicsCompanion.insert(id: uuid.v4(), noteId: noteId, topicId: strikingId));
  }

  // Basic queries
  Stream<List<Topic>> watchAllTopics() {
    return (select(topics)..orderBy([(t) => OrderingTerm(expression: t.order)])).watch();
  }

  Future<List<Topic>> getAllTopicsOnce() => (select(topics)..orderBy([(t) => OrderingTerm(expression: t.order)])).get();

  Stream<List<Note>> watchNotesForTopic(String? topicId) {
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

  Future<String> createNote(String title, String? content, {List<String>? topicIds, String? parentId}) async {
    const uuid = Uuid();
    final noteId = uuid.v4();

    // Determine sort order
    int sortOrder = 0;
    if (parentId != null) {
      final siblings = await (select(notes)..where((n) => n.parentId.equals(parentId))).get();
      sortOrder = siblings.length;
    } else {
      final topLevel = await (select(notes)..where((n) => n.parentId.isNull())).get();
      sortOrder = topLevel.length;
    }

    await into(notes).insert(NotesCompanion.insert(
      id: noteId,
      title: title,
      content: Value(content),
      parentId: Value(parentId),
      sortOrder: Value(sortOrder),
    ));

    // Link to topics if provided
    if (topicIds != null) {
      for (final topicId in topicIds) {
        await into(noteTopics).insert(NoteTopicsCompanion.insert(
          id: uuid.v4(),
          noteId: noteId,
          topicId: topicId,
        ));
      }
    }

    return noteId;
  }

  Future<List<Note>> getChildNotes(String parentId) async {
    return await (select(notes)
      ..where((n) => n.parentId.equals(parentId))
      ..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])
    ).get();
  }

  // Get hierarchical notes as a tree structure
  Stream<List<Note>> watchHierarchicalNotes() {
    return (select(notes)..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])).watch();
  }

  Future<List<Note>> getRootNotes() async {
    return await (select(notes)
      ..where((n) => n.parentId.isNull())
      ..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])
    ).get();
  }

  Future<void> moveNote(String noteId, String? newParentId, int newSortOrder) async {
    await (update(notes)..where((n) => n.id.equals(noteId))).write(NotesCompanion(
      parentId: Value(newParentId),
      sortOrder: Value(newSortOrder),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> toggleNoteExpanded(String noteId, bool isExpanded) async {
    await (update(notes)..where((n) => n.id.equals(noteId))).write(NotesCompanion(
      isExpanded: Value(isExpanded),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<Note?> getNoteById(String id) async {
    return await (select(notes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateNoteContent(String id, String? content, {String? title}) async {
    await (update(notes)..where((tbl) => tbl.id.equals(id))).write(NotesCompanion(content: Value(content), title: title != null ? Value(title) : Value.absent(), updatedAt: Value(DateTime.now())));
  }

  Future<void> deleteNote(String id) async {
    // First, get the note that's being deleted to know its parentId and sortOrder
    final noteToDelete = await (select(notes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (noteToDelete == null) return; // Note doesn't exist
    
    // Find all child notes of the note being deleted
    final childNotes = await (select(notes)..where((n) => n.parentId.equals(id))..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])).get();
    
    // Move all child notes to the same level as the deleted note
    // Position them after the deleted note's position
    int nextSortOrder = noteToDelete.sortOrder + 1;
    
    for (final child in childNotes) {
      await (update(notes)..where((n) => n.id.equals(child.id))).write(
        NotesCompanion(
          parentId: Value(noteToDelete.parentId), // Move to same level as deleted note
          sortOrder: Value(nextSortOrder), // Position them sequentially after deleted note
          updatedAt: Value(DateTime.now()),
        ),
      );
      nextSortOrder++;
    }
    
    // Update sort order for other sibling notes that come after the deleted note
    // to make room for the moved child notes
    if (childNotes.isNotEmpty) {
      Expression<bool> siblingCondition;
      if (noteToDelete.parentId != null) {
        siblingCondition = notes.parentId.equals(noteToDelete.parentId!) & 
                          notes.sortOrder.isBiggerThanValue(noteToDelete.sortOrder) & 
                          notes.id.equals(id).not();
      } else {
        siblingCondition = notes.parentId.isNull() & 
                          notes.sortOrder.isBiggerThanValue(noteToDelete.sortOrder) & 
                          notes.id.equals(id).not();
      }
      
      final siblingsToUpdate = await (select(notes)..where((n) => siblingCondition)).get();
      
      for (final sibling in siblingsToUpdate) {
        await (update(notes)..where((n) => n.id.equals(sibling.id))).write(
          NotesCompanion(
            sortOrder: Value(sibling.sortOrder + childNotes.length), // Shift by number of moved children
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
    
    // Now safely delete the note (child data like media items and steps 
    // will be deleted automatically due to CASCADE constraints)
    await (delete(notes)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> addMedia(String noteId, String type, String path, {int position = 0}) async {
    const uuid = Uuid();
    await into(mediaItems).insert(MediaItemsCompanion.insert(id: uuid.v4(), noteId: noteId, type: type, path: path, position: Value(position)));
  }

  Future<List<MediaItem>> getMediaForNoteOnce(String noteId) => (select(mediaItems)..where((m) => m.noteId.equals(noteId))..orderBy([(m) => OrderingTerm(expression: m.position)])).get();

  // Steps methods
  Future<List<Step>> getStepsForNote(String noteId) => (select(steps)..where((s) => s.noteId.equals(noteId))..orderBy([(s) => OrderingTerm(expression: s.stepOrder)])).get();

  Future<String> createStep(String noteId, String title, {String? description, String? imageUrl, String? duration, String? notes}) async {
    const uuid = Uuid();
    final stepId = uuid.v4();
    final maxOrder = await (selectOnly(steps)..addColumns([steps.stepOrder.max()])..where(steps.noteId.equals(noteId))).getSingle();
    final nextOrder = (maxOrder.read(steps.stepOrder.max()) ?? 0) + 1;
    
    await into(steps).insert(StepsCompanion.insert(
      id: stepId,
      noteId: noteId,
      stepOrder: nextOrder,
      title: title,
      description: Value(description),
      imageUrl: Value(imageUrl),
      duration: Value(duration),
      notes: Value(notes),
    ));
    
    return stepId;
  }

  Future<void> updateStep(String stepId, {String? title, String? description, String? imageUrl, String? duration, String? notes}) async {
    await (update(steps)..where((s) => s.id.equals(stepId))).write(StepsCompanion(
      title: title != null ? Value(title) : Value.absent(),
      description: Value(description),
      imageUrl: Value(imageUrl),
      duration: Value(duration),
      notes: Value(notes),
    ));
  }

  Future<void> deleteStep(String stepId) async {
    await (delete(steps)..where((s) => s.id.equals(stepId))).go();
  }

  Future<void> reorderSteps(String noteId, List<String> stepIds) async {
    await transaction(() async {
      for (int i = 0; i < stepIds.length; i++) {
        await (update(steps)..where((s) => s.id.equals(stepIds[i]))).write(StepsCompanion(
          stepOrder: Value(i),
        ));
      }
    });
  }
}
