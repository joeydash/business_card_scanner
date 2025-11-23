import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/business_card_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('business_cards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version for migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create groups table
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create cards table with group_id
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personName TEXT,
        jobTitle TEXT,
        pronouns TEXT,
        emails TEXT,
        phones TEXT,
        websites TEXT,
        linkedIn TEXT,
        twitter TEXT,
        companyName TEXT,
        department TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        postalCode TEXT,
        country TEXT,
        fax TEXT,
        tagline TEXT,
        rawText TEXT,
        confidenceScores TEXT,
        scannedAt TEXT,
        groupId INTEGER,
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create groups table
      await db.execute('''
        CREATE TABLE groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      // Add groupId column to existing cards table
      await db.execute('ALTER TABLE cards ADD COLUMN groupId INTEGER');
    }
  }

  Future<int> create(BusinessCardData card) async {
    final db = await instance.database;
    return await db.insert('cards', card.toMap());
  }

  Future<BusinessCardData> readCard(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'cards',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return BusinessCardData.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<BusinessCardData>> readAllCards() async {
    final db = await instance.database;
    final result = await db.query('cards', orderBy: 'scannedAt DESC');
    return result.map((json) => BusinessCardData.fromMap(json)).toList();
  }

  // Paginated query for lazy loading
  Future<List<BusinessCardData>> readCardsPaginated({
    required int limit,
    required int offset,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'cards',
      orderBy: 'scannedAt DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => BusinessCardData.fromMap(json)).toList();
  }

  // Get total count of cards
  Future<int> getCardCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM cards');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(BusinessCardData card, int id) async {
    final db = await instance.database;
    return db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final db = await instance.database;
    await db.delete('cards');
  }

  // Group operations
  Future<int> createGroup(String name) async {
    final db = await instance.database;
    return await db.insert('groups', {
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> readAllGroups() async {
    final db = await instance.database;
    return await db.query('groups', orderBy: 'createdAt DESC');
  }

  Future<int> updateGroup(int id, String newName) async {
    final db = await instance.database;
    return await db.update(
      'groups',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await instance.database;
    // Set groupId to null for cards in this group
    await db.update(
      'cards',
      {'groupId': null},
      where: 'groupId = ?',
      whereArgs: [id],
    );
    // Delete the group
    return await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<BusinessCardData>> readCardsByGroup(int? groupId) async {
    final db = await instance.database;
    final result = await db.query(
      'cards',
      where: groupId == null ? 'groupId IS NULL' : 'groupId = ?',
      whereArgs: groupId == null ? null : [groupId],
      orderBy: 'scannedAt DESC',
    );
    return result.map((json) => BusinessCardData.fromMap(json)).toList();
  }

  Future<int> getGroupCardCount(int? groupId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE ${groupId == null ? 'groupId IS NULL' : 'groupId = ?'}',
      groupId == null ? null : [groupId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
