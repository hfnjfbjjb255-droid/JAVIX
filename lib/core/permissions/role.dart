/// The two separated editions of the app.
enum AppEdition { user, developer }

/// Fine-grained permissions. Developer accounts hold all of them;
/// user accounts hold only the safe subset.
enum AppPermission {
  controlDevices,
  cameraSearch,
  reminders,
  managePermissions,
  pushUpdates,
  viewDiagnostics,
  manageUsers,
}

class Role {
  final AppEdition edition;
  final Set<AppPermission> permissions;

  const Role._(this.edition, this.permissions);

  static const Role user = Role._(AppEdition.user, {
    AppPermission.controlDevices,
    AppPermission.cameraSearch,
    AppPermission.reminders,
  });

  static final Role developer = Role._(AppEdition.developer, AppPermission.values.toSet());

  bool can(AppPermission p) => permissions.contains(p);
}
