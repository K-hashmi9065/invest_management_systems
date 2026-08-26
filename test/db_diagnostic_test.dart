import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() {
  test('diagnose database', () async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    
    final appData = Platform.environment['PROGRAMDATA'] ?? 'C:\\ProgramData';
    final dbPath = join(appData, 'GroupInvestmentManagement', 'database', 'group_investment.db');
    
    debugPrint('Connecting to database at: $dbPath');
    if (!File(dbPath).existsSync()) {
      debugPrint('DB file does not exist!');
      return;
    }
    
    var db = await databaseFactory.openDatabase(dbPath);
    
    debugPrint('=== USERS ===');
    var users = await db.query('users');
    for (var u in users) {
      debugPrint('ID: ${u['id']}, Username: "${u['username']}", FullName: "${u['full_name']}", Role: "${u['role']}"');
    }
    
    debugPrint('\n=== WITHDRAWALS ===');
    var withdrawals = await db.query('withdrawals');
    for (var w in withdrawals) {
      debugPrint('ID: ${w['id']}, MemberID: ${w['member_id']}, ApprovedBy: "${w['approved_by']}", Status: "${w['status']}"');
    }
    
    debugPrint('\n=== JOINED WITHDRAWALS ===');
    var joinedW = await db.rawQuery('''
      SELECT w.*, u.full_name as approver_name, u.role as approver_role
      FROM withdrawals w
      LEFT JOIN users u ON w.approved_by = u.username
    ''');
    for (var j in joinedW) {
      debugPrint('ID: ${j['id']}, ApprovedBy: "${j['approved_by']}", ApproverName: "${j['approver_name']}", ApproverRole: "${j['approver_role']}"');
    }

    debugPrint('\n=== JOINED CONTRIBUTION REQUESTS ===');
    var joinedC = await db.rawQuery('''
      SELECT r.*, u.full_name as reviewer_name, u.role as reviewer_role
      FROM contribution_requests r
      LEFT JOIN users u ON r.reviewed_by = u.username
    ''');
    for (var j in joinedC) {
      debugPrint('ID: ${j['id']}, ReviewedBy: "${j['reviewed_by']}", ReviewerName: "${j['reviewer_name']}", ReviewerRole: "${j['reviewer_role']}"');
    }
    
    await db.close();
  });
}
