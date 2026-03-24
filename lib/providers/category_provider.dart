import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Future<void> fetchCategories() async {
    _categories = await DatabaseHelper().getCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final newCategory = Category(name: name);
    await DatabaseHelper().insertCategory(newCategory);
    await fetchCategories();
  }

  Future<void> updateCategory(Category category) async {
    await DatabaseHelper().updateCategory(category);
    await fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper().deleteCategory(id);
    await fetchCategories();
  }
}
