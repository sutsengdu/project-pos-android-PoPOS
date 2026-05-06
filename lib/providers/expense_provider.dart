import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Expense> get expenses => _expenses;

  Future<void> fetchExpenses() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.getExpenses();
    _expenses = maps.map((m) => Expense.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense.toMap());
    await fetchExpenses();
  }

  Future<int> deleteExpense(int id) async {
    final result = await _dbHelper.deleteExpense(id);
    await fetchExpenses();
    return result;
  }

  double getTotalExpenses(DateTime start, DateTime end) {
    double total = 0;
    for (var expense in _expenses) {
      final dt = DateTime.parse(expense.timestamp);
      if (dt.isAfter(start.subtract(const Duration(seconds: 1))) && dt.isBefore(end)) {
        total += expense.amount;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> getExpensesForChart(String period, {int offset = 0}) {
    final now = DateTime.now();
    if (period == 'daily') {
      final baseDate = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      final Map<int, double> hourlyTotals = {};
      for (int i = 0; i < 24; i++) hourlyTotals[i] = 0.0;
      
      for (var e in _expenses) {
        final dt = DateTime.parse(e.timestamp);
        if (dt.year == baseDate.year && dt.month == baseDate.month && dt.day == baseDate.day) {
          hourlyTotals[dt.hour] = (hourlyTotals[dt.hour] ?? 0) + e.amount;
        }
      }
      
      return hourlyTotals.entries
          .where((e) => e.value > 0 || (e.key >= 8 && e.key <= 20))
          .map((e) => {'label': '${e.key}h', 'value': e.value})
          .toList();

    } else if (period == 'weekly') {
      final Map<String, double> dailyTotals = {};
      final DateFormat formatter = DateFormat('E');
      final baseStart = DateTime(now.year, now.month, now.day).add(Duration(days: offset * 7));
      
      for (int i = 6; i >= 0; i--) {
        final d = baseStart.subtract(Duration(days: i));
        dailyTotals[formatter.format(d)] = 0.0;
      }
      
      final weekStart = baseStart.subtract(const Duration(days: 6));
      final weekEnd = baseStart.add(const Duration(days: 1));
      
      for (var e in _expenses) {
        final dt = DateTime.parse(e.timestamp);
        if (dt.isAfter(weekStart.subtract(const Duration(seconds: 1))) && dt.isBefore(weekEnd)) {
          final label = formatter.format(dt);
          dailyTotals[label] = (dailyTotals[label] ?? 0) + e.amount;
        }
      }
      
      return dailyTotals.entries.map((e) => {'label': e.key, 'value': e.value}).toList();
      
    } else { // monthly
      final List<Map<String, dynamic>> weeklyData = [];
      final baseStart = DateTime(now.year, now.month, now.day).add(Duration(days: offset * 28));
      
      for (int i = 3; i >= 0; i--) {
        final weekEnd = baseStart.subtract(Duration(days: i * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));
        
        double total = 0;
        for (var e in _expenses) {
          final dt = DateTime.parse(e.timestamp);
          if (dt.isAfter(weekStart.subtract(const Duration(seconds: 1))) && dt.isBefore(weekEnd.add(const Duration(days: 1)))) {
            total += e.amount;
          }
        }
        
        weeklyData.insert(0, {
          'label': 'W${4-i}',
          'value': total,
        });
      }
      return weeklyData;
    }
  }
}
