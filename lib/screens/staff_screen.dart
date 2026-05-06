import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/staff_provider.dart';
import '../providers/settings_provider.dart';
import '../models/staff.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final sp = Provider.of<SettingsProvider>(context);

    if (sp.settings.isProUnlocked && !staffProvider.hasPermission('manage_staff')) {
      return Scaffold(
        appBar: AppBar(title: Text(sp.languageCode == 'my' ? 'ဝန်ထမ်းများ စီမံရန်' : 'Staff Management')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sp.languageCode == 'my' ? 'ဝန်ထမ်းများ စီမံရန်' : 'Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddStaffDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!staffProvider.staff.any((s) => s.isAdmin))
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                   const Icon(Icons.warning_amber_rounded, color: Colors.red),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       sp.languageCode == 'my' 
                        ? 'သတိပေးချက် - စနစ်အား စီမံခန့်ခွဲရန် ဦးစွာ Admin Role တစ်ခုကို ထည့်သွင်းပေးပါ' 
                        : 'Warning: Please add an Admin Role first to manage the system.',
                       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                     ),
                   ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: staffProvider.staff.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final s = staffProvider.staff[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: s.isAdmin ? Colors.orange : Colors.blue,
                      child: Icon(s.isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
                    ),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s.role),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditStaffDialog(context, s),
                        ),
                        if (staffProvider.currentStaff?.id != s.id)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _showDeleteConfirm(context, staffProvider, s),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    String role = 'Cashier';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                controller: pinController, 
                decoration: const InputDecoration(labelText: 'PIN (4 digits)'),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: ['Admin', 'Manager', 'Cashier'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && pinController.text.length == 4) {
                  final s = Staff(name: nameController.text, role: role, pin: pinController.text);
                  Provider.of<StaffProvider>(context, listen: false).addStaff(s);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, Staff s) {
    final nameController = TextEditingController(text: s.name);
    final pinController = TextEditingController(text: s.pin);
    String role = s.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                controller: pinController, 
                decoration: const InputDecoration(labelText: 'PIN (4 digits)'),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: ['Admin', 'Manager', 'Cashier'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && pinController.text.length == 4) {
                  final updated = s.copyWith(name: nameController.text, role: role, pin: pinController.text);
                  Provider.of<StaffProvider>(context, listen: false).updateStaff(updated);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, StaffProvider provider, Staff s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${s.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteStaff(s.id!);
              Navigator.pop(context);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
