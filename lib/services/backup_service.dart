import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final dbPath = p.join(await getDatabasesPath(), 'pos_database.db');
    final file = File(dbPath);

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final now = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: 'pos_backup_$now.db',
        bytes: bytes,
      );

      // On some platforms saveFile returns the path but doesn't write bytes, 
      // or we might want to fallback to Share if saveFile returns null (user canceled)
      if (outputPath == null) {
        // Fallback to share if the user canceled or it's not supported
        await Share.shareXFiles([XFile(dbPath)], text: 'POS Database Backup');
      }
    }
  }

  static Future<bool> restoreBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final pickupFile = File(result.files.single.path!);
      final dbPath = p.join(await getDatabasesPath(), 'pos_database.db');
      
      // Close database first
      await DatabaseHelper().database.then((db) => db.close());
      
      // Overwrite
      await pickupFile.copy(dbPath);
      
      return true;
    }
    return false;
  }

  static Future<void> checkAndRunAutoBackup(String interval, String? lastBackupStr) async {
    if (interval == 'none') return;

    DateTime? lastBackup;
    if (lastBackupStr != null) {
      lastBackup = DateTime.tryParse(lastBackupStr);
    }

    final now = DateTime.now();
    bool shouldBackup = false;

    if (lastBackup == null) {
      shouldBackup = true;
    } else {
      final difference = now.difference(lastBackup).inDays;
      if (interval == 'daily' && difference >= 1) shouldBackup = true;
      if (interval == 'weekly' && difference >= 7) shouldBackup = true;
      if (interval == 'monthly' && difference >= 30) shouldBackup = true;
    }

    if (shouldBackup) {
      await runInternalBackup();
    }
  }

  static Future<void> runInternalBackup() async {
    final dbPath = p.join(await getDatabasesPath(), 'pos_database.db');
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDocDir.path, 'backups'));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(backupDir.path, 'backup_$timestamp.db');
    
    await File(dbPath).copy(backupPath);
    
    // Cleanup old backups (keep last 5)
    final files = backupDir.listSync().whereType<File>().toList();
    if (files.length > 5) {
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      for (int i = 0; i < files.length - 5; i++) {
        await files[i].delete();
      }
    }
  }
}
