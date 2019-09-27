import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'message.dart';
import 'user.dart';
import 'dart:convert';

class UserDataBase {
  UserDataBase._();
  final _database = _create();

  static UserDataBase _instance;
  static UserDataBase get instance {
    if (_instance == null) {
      _instance = UserDataBase._();
    }
    return _instance;
  }

  static Future<Database> _create() async => openDatabase(
        join(await getDatabasesPath(), 'user_database.db'),
        onCreate: (db, version) {
          // Run the CREATE TABLE statement on the database.
          db.execute(
            "CREATE TABLE users(uid TEXT NOT NULL UNIQUE," +
                " username TEXT, picUrl TEXT, message_count INTEGER," +
                " last_message_time INTEGER, last_status_time INTEGER," +
                " last_message TEXT, bio TEXT)",
          );

          return db.execute(
            "CREATE TABLE this_user(${ThisUser.thisUserSQLScheme})",
          );
        },
        // Set the version. This executes the onCreate function and provides a
        // path to perform database upgrades and downgrades.
        version: 1,
      );

  Future<Map<String, dynamic>> getThisUser() async {
    final Database db = await _database;
    final userTable = await db.query("this_user");
    return userTable.isNotEmpty ? userTable[0] : null;
  }

  Future<void> setThisUser(Map<String, dynamic> userMap) async {
    final db = await _database;
    await db.insert(
      "this_user",
      userMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateThisUserLocalData({
    List<String> addRequests = const [],
    List<String> removeRequests = const [],
    int lastUserFetch,
    Map<String, dynamic> dataMap = const {},
  }) async {
    final db = await _database;
    return db.transaction((transaction) async {
      final user = await transaction.query(
        "this_user",
        columns: ["localData", "uid"],
      );

      final localData = json.decode(user[0]["localData"]);

      final data = {
        "localData": json.encode({
          "lastUserFetch": lastUserFetch ?? localData["lastUserFetch"],
          "unSeenRequests": addRequests != null
              ? ((localData["unSeenRequests"] as List<String> ?? <String>[])
                ..removeWhere((value) => addRequests.contains(value))
                ..addAll(addRequests)
                ..removeWhere((value) => removeRequests.contains(value)))
              : [],
        }..addEntries(dataMap.entries))
      };
      return await db.update(
        'this_user',
        data,
        where: "uid = ?",
        whereArgs: [user[0]["uid"]],
      );
    });
  }

  Future<void> removeThisUser() async {
    final Database db = await _database;
    await db.query('this_user');
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final Database db = await _database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLastUserMessage(
    String uid,
    TextMessage message, {
    int count = 1,
    bool increaseCount = true,
  }) async {
    final Database db = await _database;
    return db.transaction((transaction) async {
      Map<String, dynamic> data = {
        "last_message": message?.toJsonString() ?? "",
        "last_message_time": message?.timeStamp ?? 0,
      };

      if (increaseCount) {
        final user = await transaction.query(
          "users",
          columns: ["message_count"],
          where: "uid = ?",
          whereArgs: [uid],
        );
        int messageCount = count;
        if (user.isNotEmpty) {
          messageCount += (user[0]["message_count"] ?? 0);
        }
        data = {
          "last_message": data["last_message"],
          "last_message_time": data["last_message_time"],
          "message_count": messageCount,
        };
      }

      return await db.update(
        'users',
        data,
        where: "uid = ?",
        whereArgs: [uid],
      );
    });
  }

  Future<void> updateReadMessages(String uid) async {
    final Database db = await _database;
    await db.update(
      'users',
      {"message_count": 0},
      where: "uid = ?",
      whereArgs: [uid],
    );
  }

  Future<void> updateLastUserStatus(String uid, int statusTime) async {
    final Database db = await _database;
    await db.update(
      'users',
      {"last_status_time": statusTime ?? 0},
      where: "uid = ?",
      whereArgs: [uid],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentlyMessagedUsers() async {
    final Database db = await _database;
    return await db.query(
      "users",
      where: "last_message_time IS NOT NULL AND last_message_time != ?",
      whereArgs: [0],
      orderBy: "last_message_time DESC",
    );
  }

  Future<List<Map<String, dynamic>>> getUsersWithCurrentStatus(
      int timestamp) async {
    final Database db = await _database;
    return await db.query(
      "users",
      where: "last_status_time IS NOT NULL AND last_status_time > ?",
      whereArgs: [timestamp - 24 * 60 * 60000],
      orderBy: "last_status_time DESC",
    );
  }

  Future<Map<String, dynamic>> getUser(String uid) async {
    final Database db = await _database;
    final result = await db.query(
      "users",
      where: "uid = ?",
      whereArgs: [uid],
    );

    return result.isNotEmpty ? result[0] : null;
  }

  Future<void> deleteUser(String uid) async {
    final Database db = await _database;
    await db.delete(
      "users",
      where: "uid = ?",
      whereArgs: [uid],
    );
  }

  Future<void> deleteAllUsers() async {
    final Database db = await _database;
    await db.delete("users");
  }

  Future<void> getAllUsers() async {
    final Database db = await _database;
    await db.query('users');
  }

  Future<void> clearDatabase() async {
    await deleteAllUsers();
    await removeThisUser();
  }
}
