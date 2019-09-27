import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';

class MessageDatabase {
  MessageDatabase._();
  final _database = _create();

  static MessageDatabase _instance;
  static MessageDatabase get instance {
    if (_instance == null) {
      _instance = MessageDatabase._();
    }
    return _instance;
  }

  static Future<Database> _create() async => openDatabase(
        join(await getDatabasesPath(), 'message_database.db'),
        onCreate: (db, version) {
          // Run the CREATE TABLE statement on the database.

          db.execute(
            "CREATE TABLE friend_requests(messageId TEXT NOT NULL UNIQUE," +
                " userId TEXT, username TEXT, roomId TEXT, timestamp INTEGER," +
                " type TEXT, sentTo TEXT, action TEXT)",
          );

          return db.execute(
            "CREATE TABLE text_messages(messageId TEXT NOT NULL UNIQUE," +
                " userId TEXT, username TEXT, roomId TEXT, timestamp INTEGER," +
                " type TEXT, sentTo TEXT, text TEXT, state TEXT)",
          );
        },
        // Set the version. This executes the onCreate function and provides a
        // path to perform database upgrades and downgrades.
        version: 1,
      );

  Future<List<Map<String, dynamic>>> getMessages(String roomId,
      {int startAt, int unreadCount = 0}) async {
    final Database db = await _database;
    return await db.query(
      "text_messages",
      where: "roomId = ?" + (startAt != null ? " timestamp < ?" : ""),
      whereArgs: startAt != null ? [roomId, startAt] : [roomId],
      orderBy: "timestamp DESC",
      limit: 50 + unreadCount,
    );
  }

  Future<Map<String, dynamic>> getLastMessage(String roomId) async {
    final Database db = await _database;
    final result = await db.query(
      "text_messages",
      where: "roomId = ?",
      whereArgs: [roomId],
      orderBy: "timestamp DESC",
      limit: 1,
    );
    return result.isNotEmpty ? result[0] : null;
  }

  Future<void> addMessage(Map<String, dynamic> message) async {
    final Database db = await _database;
    await db.insert(
      "text_messages",
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateMessage(Map<String, dynamic> message) async {
    final Database db = await _database;
    return await db.update(
      "text_messages",
      message,
      where: "messageId = ?",
      whereArgs: [message["messageId"]],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final Database db = await _database;
    await db.delete(
      "text_messages",
      where: "messageId",
      whereArgs: [messageId],
    );
  }

  Future<List<Map<String, dynamic>>> getRequests(String thisUserId) async {
    final Database db = await _database;
    return await db.query(
      "friend_requests",
      where: "userId != ?",
      whereArgs: [thisUserId],
      orderBy: "timestamp DESC",
    );
  }

  Future<void> addRequest(Map<String, dynamic> request) async {
    final Database db = await _database;
    await db.insert(
      "friend_requests",
      request,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeRequest(String roomId) async {
    final Database db = await _database;
    await db.delete(
      "friend_requests",
      where: "roomId = ?",
      whereArgs: [roomId],
    );
  }

  Future<void> deleteAllMessages() async {
    final Database db = await _database;
    await db.delete("text_messages");
  }

  Future<void> deleteAllRequests() async {
    final Database db = await _database;
    await db.delete("friend_requests");
  }

  Future<void> clearDatabase() async {
    await deleteAllMessages();
    await deleteAllRequests();
  }
}
