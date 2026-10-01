import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/strings_ar.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/theme/javix_theme.dart';
import '../../widgets/gold_card.dart';
import 'logs/log_viewer_screen.dart';
import 'permissions/permission_manager_screen.dart';
import 'updates/ota_manager_screen.dart';

/// Developer Edition dashboard. Completely separate navigation from the
/// user edition; every entry re-checks its permission.
class DevDashboardScreen extends StatelessWidget {
  const DevDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<PermissionService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.devDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: JavixColors.textSecondary),
            tooltip: S.switchToUser,
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _DevTile(icon: Icons.key, label: S.devPermissions,
              onTap: () => _open(context, AppPermission.managePermissions, const PermissionManagerScreen())),
          _DevTile(icon: Icons.system_update_alt, label: S.devUpdates,
              onTap: () => _open(context, AppPermission.pushUpdates, const OtaManagerScreen())),
          _DevTile(icon: Icons.terminal, label: S.devLogs,
              onTap: () => _open(context, AppPermission.viewDiagnostics, const LogViewerScreen())),
          _DevTile(icon: Icons.people_outline, label: 'المستخدمون',
              onTap: () => _open(context, AppPermission.manageUsers, const _StubScreen('إدارة المستخدمين'))),
          _DevTile(icon: Icons.memory, label: 'حالة الأجهزة',
              onTap: () => _open(context, AppPermission.viewDiagnostics, const _StubScreen('حالة الأجهزة'))),
          _DevTile(icon: Icons.security_outlined, label: 'الأمان',
              onTap: () => _open(context, AppPermission.viewDiagnostics, const _StubScreen('مركز الأمان'))),
        ],
      ),
    );
  }

  void _open(BuildContext context, AppPermission p, Widget screen) {
    final auth = context.read<PermissionService>();
    if (!auth.role.can(p)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.permissionDenied)));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _DevTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DevTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 34, color: JavixColors.gold),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen(this.title);

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)));
}
