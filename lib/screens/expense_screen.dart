import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../providers/staff_provider.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Other';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog(BuildContext context, ExpenseProvider provider, SettingsProvider settings, StaffProvider staff) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(settings.l10n('add_expense')),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: settings.l10n('expense_title')),
                  validator: (v) => v!.isEmpty ? 'Enter title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: settings.l10n('amount')),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid amount' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: ['Salary', 'Rent', 'Electricity', 'Supplies', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => _selectedCategory = v!),
                  decoration: InputDecoration(labelText: settings.l10n('category')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(settings.l10n('cancel'))),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final now = DateTime.now();
                  final expense = Expense(
                    title: _titleController.text,
                    amount: double.parse(_amountController.text),
                    category: _selectedCategory,
                    date: DateFormat('yyyy-MM-dd').format(now),
                    timestamp: now.toIso8601String(),
                    staffName: staff.currentStaff?.name ?? 'Owner',
                  );
                  provider.addExpense(expense);
                  _titleController.clear();
                  _amountController.clear();
                  Navigator.pop(context);
                }
              },
              child: Text(settings.l10n('confirm')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final staffProvider = Provider.of<StaffProvider>(context);
    final canManage = !settingsProvider.settings.isProUnlocked || staffProvider.hasPermission('manage_expenses');

    return Scaffold(
      appBar: AppBar(title: Text(settingsProvider.l10n('expenses'))),
      body: expenseProvider.expenses.isEmpty
          ? Center(child: Text(settingsProvider.l10n('no_expenses_found')))
          : ListView.builder(
              itemCount: expenseProvider.expenses.length,
              itemBuilder: (context, index) {
                final expense = expenseProvider.expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    ),
                    title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${expense.category} • ${expense.date}${expense.staffName != null ? " • ${expense.staffName}" : ""}'),
                    trailing: Text(
                      '-${expense.amount.toStringAsFixed(0)} ${settingsProvider.settings.currencySymbol}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    onLongPress: canManage ? () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(settingsProvider.l10n('delete')),
                          content: Text(settingsProvider.l10n('confirm_delete')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(settingsProvider.l10n('cancel'))),
                            TextButton(
                              onPressed: () {
                                expenseProvider.deleteExpense(expense.id!);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    } : null,
                  ),
                );
              },
            ),
      floatingActionButton: canManage ? FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context, expenseProvider, settingsProvider, staffProvider),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
