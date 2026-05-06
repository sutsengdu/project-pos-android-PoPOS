import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../services/database_helper.dart';

class StaffProvider with ChangeNotifier {
  List<Staff> _staff = [];
  Staff? _currentStaff;
  bool _isLoaded = false;

  List<Staff> get staff => _staff;
  Staff? get currentStaff => _currentStaff;
  bool get isLoaded => _isLoaded;

  Future<void> loadStaff() async {
    _staff = await DatabaseHelper().getStaff();
    _isLoaded = true;
    notifyListeners();
  }

  Future<bool> login(String pin) async {
    final staffMember = await DatabaseHelper().loginStaff(pin);
    if (staffMember != null) {
      _currentStaff = staffMember;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentStaff = null;
    notifyListeners();
  }

  Future<void> addStaff(Staff s) async {
    await DatabaseHelper().insertStaff(s);
    await loadStaff();
  }

  Future<void> updateStaff(Staff s) async {
    await DatabaseHelper().updateStaff(s);
    if (_currentStaff?.id == s.id) {
      _currentStaff = s;
    }
    await loadStaff();
  }

  Future<void> deleteStaff(int id) async {
    await DatabaseHelper().deleteStaff(id);
    await loadStaff();
  }

  bool hasPermission(String action) {
    // If no staff is logged in, we default to the "Owner/Admin" version with full access
    if (_currentStaff == null) return true;
    if (_currentStaff!.isAdmin) return true;
    
    final role = _currentStaff!.role;

    switch (action) {
      case 'view_profit':
      case 'manage_inventory':
      case 'manage_expenses':
        return role == 'Manager';
      case 'delete_sale':
      case 'access_settings':
      case 'manage_staff':
        return false; // Only Admin
      default:
        return true; // Basic actions like viewing dashboard revenue
    }
  }
}
