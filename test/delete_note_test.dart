// test/delete_note_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:martial_notes/src/db/app_db.dart';
import 'package:drift/native.dart';

void main() {
  group('Note Deletion Tests', () {
    late AppDb database;

    setUp(() {
      // Create an in-memory database for testing
      database = AppDb.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('Deleting a note should preserve child notes', (WidgetTester tester) async {
      // Create parent note
      final parentId = await database.createNote('Parent Note', 'Parent content');
      
      // Create child notes
      final child1Id = await database.createNote('Child 1', 'Child 1 content', parentId: parentId);
      final child2Id = await database.createNote('Child 2', 'Child 2 content', parentId: parentId);
      
      // Create grandchild note
      final grandchildId = await database.createNote('Grandchild', 'Grandchild content', parentId: child1Id);
      
      // Verify initial structure (including seeded data)
      final initialTopLevel = await database.getRootNotes();
      final initialChildren = await database.getChildNotes(parentId);
      final initialGrandchildren = await database.getChildNotes(child1Id);
      
      expect(initialTopLevel.length, 2); // Parent note + seeded "Front Kick" note
      expect(initialChildren.length, 2); // Two children
      expect(initialGrandchildren.length, 1); // One grandchild
      
      // Delete the parent note
      await database.deleteNote(parentId);
      
      // Verify child notes moved to top level
      final newTopLevel = await database.getRootNotes();
      final remainingChildren = await database.getChildNotes(child1Id);
      
      expect(newTopLevel.length, 3); // Seeded note + Child1 + Child2 should be at top level now
      expect(remainingChildren.length, 1); // Grandchild should still be under Child1
      
      // Verify the child notes are the correct ones
      final child1After = await database.getNoteById(child1Id);
      final child2After = await database.getNoteById(child2Id);
      final grandchildAfter = await database.getNoteById(grandchildId);
      
      expect(child1After?.parentId, isNull); // Child1 should now be top level
      expect(child2After?.parentId, isNull); // Child2 should now be top level
      expect(grandchildAfter?.parentId, child1Id); // Grandchild should still be under Child1
    });

    testWidgets('Deleting a child note should preserve its children', (WidgetTester tester) async {
      // Create parent note
      final parentId = await database.createNote('Parent Note', 'Parent content');
      
      // Create child note
      final childId = await database.createNote('Child Note', 'Child content', parentId: parentId);
      
      // Create grandchild notes
      final grandchild1Id = await database.createNote('Grandchild 1', 'GC1 content', parentId: childId);
      final grandchild2Id = await database.createNote('Grandchild 2', 'GC2 content', parentId: childId);
      
      // Delete the child note
      await database.deleteNote(childId);
      
      // Verify grandchildren moved to parent level
      final parentChildren = await database.getChildNotes(parentId);
      
      expect(parentChildren.length, 2); // Grandchildren should now be under parent
      
      // Verify the grandchildren are correctly moved
      final gc1After = await database.getNoteById(grandchild1Id);
      final gc2After = await database.getNoteById(grandchild2Id);
      
      expect(gc1After?.parentId, parentId); // Should be under parent now
      expect(gc2After?.parentId, parentId); // Should be under parent now
    });
  });
}