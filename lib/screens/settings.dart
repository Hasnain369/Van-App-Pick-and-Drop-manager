import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/db.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool loading = false;

  Future<void> backup() async {
    setState(() => loading = true);
    try {
      final path = await DB.backup();
      // Use application/octet-stream so the OS treats it as a raw file
      // (not something to "open") — prevents "unsupported file type" errors
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/octet-stream')],
        subject: 'Van App Backup',
        text:
            'Save this file safely. Use "Restore" in Van App to recover data.',
      );
      snack('Backup shared!', true);
    } catch (e) {
      snack('Backup failed: $e', false);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> restore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will replace ALL current data. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Allow any file type so user can pick the .db from Downloads/WhatsApp
    final res = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
      withReadStream: false,
    );
    if (res == null || res.files.single.path == null) return;

    setState(() => loading = true);
    try {
      await DB.restore(res.files.single.path!);
      snack(
        'Restored successfully! Restart the app if data looks wrong.',
        true,
      );
    } catch (e) {
      snack('Restore failed: $e', false);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void snack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // App header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.directions_bus, size: 44, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Van Driver Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All data stored on your phone',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Data Backup',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.upload,
                  color: const Color(0xFF2E7D32),
                  title: 'Export Backup',
                  subtitle: 'Share your data via WhatsApp, Drive, or Email',
                  onTap: backup,
                  btnLabel: 'Backup Now',
                ),
                const SizedBox(height: 10),
                _Tile(
                  icon: Icons.download,
                  color: const Color(0xFF1565C0),
                  title: 'Restore Backup',
                  subtitle: 'Load data from a previous backup file',
                  onTap: restore,
                  btnLabel: 'Restore',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBD0FF)),
                  ),
                  child: const Text(
                    '💡 Tip: Backup your data regularly. Share the backup file to WhatsApp saved messages or Google Drive for safe storage.',
                    style: TextStyle(
                      color: Color(0xFF3D4A6B),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, btnLabel;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.btnLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(btnLabel),
          ),
        ],
      ),
    );
  }
}
