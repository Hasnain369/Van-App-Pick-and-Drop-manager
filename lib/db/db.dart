import 'dart:io';
import 'package:flutter_application_1/model/model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DB {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = p.join(await getDatabasesPath(), 'van.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          '''CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, contact TEXT, school TEXT, class TEXT, address TEXT, fee REAL)''',
        );
        await db.execute('''CREATE TABLE daily(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER, date TEXT, picked INTEGER DEFAULT 0, dropped INTEGER DEFAULT 0,
        UNIQUE(student_id, date))''');
        await db.execute('''CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER, month INTEGER, year INTEGER, amount REAL, status TEXT DEFAULT "unpaid",
        UNIQUE(student_id, month, year))''');
      },
    );
  }

  // ── Students ──────────────────────────────────────────────────────────────

  static Future<int> addStudent(Student s) async =>
      (await db).insert('students', s.toMap()..remove('id'));

  static Future<List<Student>> getStudents([String query = '']) async {
    final d = await db;
    final rows = query.isEmpty
        ? await d.query('students', orderBy: 'name')
        : await d.query(
            'students',
            where: 'name LIKE ? OR school LIKE ?',
            whereArgs: ['%$query%', '%$query%'],
            orderBy: 'name',
          );
    return rows.map(Student.fromMap).toList();
  }

  static Future<void> updateStudent(Student s) async => (await db).update(
    'students',
    s.toMap(),
    where: 'id=?',
    whereArgs: [s.id],
  );

  static Future<void> deleteStudent(int id) async {
    final d = await db;
    await d.delete('students', where: 'id=?', whereArgs: [id]);
    await d.delete('daily', where: 'student_id=?', whereArgs: [id]);
    await d.delete('payments', where: 'student_id=?', whereArgs: [id]);
  }

  // ── Daily ─────────────────────────────────────────────────────────────────

  static Future<void> upsertDaily(DailyRecord r) async => (await db).insert(
    'daily',
    r.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  static Future<List<DailyRecord>> getDailyByDate(String date) async {
    final rows = await (await db).query(
      'daily',
      where: 'date=?',
      whereArgs: [date],
    );
    return rows.map(DailyRecord.fromMap).toList();
  }

  static Future<int> countPicked(String date) async {
    final res = await (await db).rawQuery(
      'SELECT COUNT(*) c FROM daily WHERE date=? AND picked=1',
      [date],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  static Future<int> countDropped(String date) async {
    final res = await (await db).rawQuery(
      'SELECT COUNT(*) c FROM daily WHERE date=? AND dropped=1',
      [date],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  static Future<void> upsertPayment(Payment p) async => (await db).insert(
    'payments',
    p.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  static Future<List<Payment>> getPayments(int month, int year) async {
    final rows = await (await db).query(
      'payments',
      where: 'month=? AND year=?',
      whereArgs: [month, year],
    );
    return rows.map(Payment.fromMap).toList();
  }

  static Future<void> ensurePayments(
    List<Student> students,
    int month,
    int year,
  ) async {
    final existing = await getPayments(month, year);
    final existingIds = existing.map((p) => p.studentId).toSet();
    for (final s in students) {
      if (!existingIds.contains(s.id)) {
        await upsertPayment(
          Payment(studentId: s.id, month: month, year: year, amount: s.fee),
        );
      }
    }
  }

  static Future<int> countUnpaid(int month, int year) async {
    final total =
        Sqflite.firstIntValue(
          await (await db).rawQuery('SELECT COUNT(*) FROM students'),
        ) ??
        0;
    final paid =
        Sqflite.firstIntValue(
          await (await db).rawQuery(
            'SELECT COUNT(*) FROM payments WHERE month=? AND year=? AND status="paid"',
            [month, year],
          ),
        ) ??
        0;
    return total - paid;
  }

  // ── Backup / Restore ──────────────────────────────────────────────────────

  static Future<String> backup() async {
    final src = p.join(await getDatabasesPath(), 'van.db');
    final dir =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dest = p.join(
      dir.path,
      'van_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    await File(src).copy(dest);
    return dest;
  }

  static Future<void> restore(String path) async {
    final dest = p.join(await getDatabasesPath(), 'van.db');
    await _db?.close();
    _db = null;
    await File(path).copy(dest);
    _db = await _init();
  }
}
