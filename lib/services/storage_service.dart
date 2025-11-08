import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _app = Hive.box('app');
  final _trips = Hive.box('trips');
  final _expenses = Hive.box('expenses');

  // Users
  AppUser? get currentUser {
    final json = _app.get('currentUser');
    if (json == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(json));
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final now = DateTime.now();
    final uid = _generateShortUserId();
    final user = AppUser(
      userId: uid,
      email: email,
      displayName: displayName,
      createdAt: now,
    );
    await _app.put('currentUser', user.toJson());
    await _app.put('user_$email', {'password': password, 'userId': uid});
    await _app.put('user_profile_$uid', user.toJson());
  }

  Future<bool> loginUser(String email, String password) async {
    final userData = _app.get('user_$email');
    if (userData == null) return false;
    final data = Map<String, dynamic>.from(userData);
    if (data['password'] != password) return false;
    
    final userId = data['userId'] as String;
    final userJson = _app.get('user_profile_$userId');
    if (userJson == null) return false;
    
    final user = AppUser.fromJson(Map<String, dynamic>.from(userJson));
    await _app.put('currentUser', user.toJson());
    return true;
  }

  Future<void> saveUserProfile(AppUser user) async {
    await _app.put('user_profile_${user.userId}', user.toJson());
    await _app.put('currentUser', user.toJson());
  }

  Future<void> logout() async {
    await _app.delete('currentUser');
  }

  // Trips
  Future<Trip> createTrip({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> participantUserIds,
  }) async {
    final adminId = currentUser!.userId;
    final tripId = const Uuid().v4();
    final joinCode = _generateJoinCode();
    final allParticipants = {
      adminId,
      ...participantUserIds,
    }.toList();
    final trip = Trip(
      tripId: tripId,
      title: title,
      startDate: startDate,
      endDate: endDate,
      adminUserId: adminId,
      joinCode: joinCode,
      participantUserIds: allParticipants,
    );
    await _trips.put(tripId, trip.toJson());
    return trip;
  }

  List<Trip> listMyTrips() {
    final uid = currentUser?.userId;
    if (uid == null) return [];
    return _trips.values
        .map((e) => Trip.fromJson(Map<String, dynamic>.from(e)))
        .where((t) => t.participantUserIds.contains(uid))
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  Trip? getTrip(String tripId) {
    final json = _trips.get(tripId);
    if (json == null) return null;
    return Trip.fromJson(Map<String, dynamic>.from(json));
  }

  Trip? findTripByJoinCode(String code) {
    for (final v in _trips.values) {
      final trip = Trip.fromJson(Map<String, dynamic>.from(v));
      if (trip.joinCode.toUpperCase() == code.toUpperCase()) return trip;
    }
    return null;
  }

  Future<void> joinTripByCode(String code) async {
    final trip = findTripByJoinCode(code);
    if (trip == null) {
      throw Exception('Trip not found');
    }
    final uid = currentUser!.userId;
    if (!trip.participantUserIds.contains(uid)) {
      final updated = Trip(
        tripId: trip.tripId,
        title: trip.title,
        startDate: trip.startDate,
        endDate: trip.endDate,
        adminUserId: trip.adminUserId,
        joinCode: trip.joinCode,
        participantUserIds: [...trip.participantUserIds, uid],
      );
      await _trips.put(updated.tripId, updated.toJson());
    }
  }

  Future<void> deleteTrip(String tripId) async {
    // delete all expenses for this trip
    final toDelete = _expenses.keys
        .where((k) => k is String && k.startsWith('$tripId:'))
        .toList();
    for (final k in toDelete) {
      await _expenses.delete(k);
    }
    await _trips.delete(tripId);
  }

  // Expenses
  Future<Expense> addExpense({
    required String tripId,
    required double amount,
    required String currency,
    required String paidByUserId,
    required List<String> participantUserIds,
    String? notes,
  }) async {
    final expenseId = const Uuid().v4();
    final expense = Expense(
      expenseId: expenseId,
      tripId: tripId,
      amount: amount,
      currency: currency,
      paidByUserId: paidByUserId,
      participantUserIds: participantUserIds,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _expenses.put('$tripId:$expenseId', expense.toJson());
    return expense;
  }

  List<Expense> listExpenses(String tripId) {
    final list = <Expense>[];
    for (final entry in _expenses.toMap().entries) {
      final key = entry.key;
      if (key is String && key.startsWith('$tripId:')) {
        list.add(Expense.fromJson(Map<String, dynamic>.from(entry.value)));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    await _expenses.delete('$tripId:$expenseId');
  }

  // Expense summary for a trip
  Map<String, dynamic> getExpenseSummary(String tripId) {
    final expenses = listExpenses(tripId);
    double totalAmount = 0;
    int totalExpenses = expenses.length;
    final currencyCounts = <String, int>{};
    
    for (final expense in expenses) {
      totalAmount += expense.amount;
      currencyCounts[expense.currency] = (currencyCounts[expense.currency] ?? 0) + 1;
    }
    
    return {
      'totalAmount': totalAmount,
      'totalExpenses': totalExpenses,
      'currencyCounts': currencyCounts,
      'averageAmount': totalExpenses > 0 ? totalAmount / totalExpenses : 0,
    };
  }

  // Get user display name by userId
  String? getUserDisplayName(String userId) {
    final userJson = _app.get('user_profile_$userId');
    if (userJson == null) return null;
    final user = AppUser.fromJson(Map<String, dynamic>.from(userJson));
    return user.displayName;
  }

  // Add participant to existing trip
  Future<void> addParticipantToTrip(String tripId, String participantUserId) async {
    final trip = getTrip(tripId);
    if (trip == null) throw Exception('Trip not found');
    
    if (!trip.participantUserIds.contains(participantUserId)) {
      final updated = Trip(
        tripId: trip.tripId,
        title: trip.title,
        startDate: trip.startDate,
        endDate: trip.endDate,
        adminUserId: trip.adminUserId,
        joinCode: trip.joinCode,
        participantUserIds: [...trip.participantUserIds, participantUserId],
      );
      await _trips.put(updated.tripId, updated.toJson());
    }
  }

  // Search users by display name
  List<Map<String, String>> searchUsers(String query) {
    final results = <Map<String, String>>[];
    final queryLower = query.toLowerCase();
    
    // Search through all user profiles
    for (final key in _app.keys) {
      if (key is String && key.startsWith('user_profile_')) {
        final userJson = _app.get(key);
        if (userJson != null) {
          final user = AppUser.fromJson(Map<String, dynamic>.from(userJson));
          if (user.displayName.toLowerCase().contains(queryLower) ||
              user.email.toLowerCase().contains(queryLower)) {
            results.add({
              'userId': user.userId,
              'displayName': user.displayName,
              'email': user.email,
            });
          }
        }
      }
    }
    
    // Sort by display name
    results.sort((a, b) => a['displayName']!.compareTo(b['displayName']!));
    return results;
  }

  String _generateJoinCode() {
    // 6-char alphanumeric
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _generateShortUserId() {
    // 8-char alphanumeric, more readable
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}


