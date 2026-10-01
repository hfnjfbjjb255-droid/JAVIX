import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/permissions/permission_service.dart';
import '../../../core/theme/javix_theme.dart';

/// Developer-only: grant/revoke per-user permissions (RBAC matrix).
class PermissionManagerScreen extends StatelessWidget {
  const PermissionManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data - replace with your backend users list.
    final demoUsers = ['مستخدم ١', 'مستخدم ٢', 'مستخدم ٣'];
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الأذونات')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoUsers.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: JavixColors.gold),
            title: Text(demoUsers[i]),
            subtitle: const Text('صلاحيات النسخة العامة (آمنة)', style: TextStyle(color: JavixColors.textSecondary, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, color: JavixColors.textSecondary),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اربط هذه الشاشة بواجهة إدارة الأذونات في الخادم')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
