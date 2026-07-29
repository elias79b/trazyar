enum AppRole {
  owner,
  consultant,
  company,
  unknown;

  static AppRole fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'owner':
        return AppRole.owner;
      case 'consultant':
        return AppRole.consultant;
      case 'company':
      case 'admin':
      case 'accountant':
      case 'member':
        return AppRole.company;
      default:
        return AppRole.unknown;
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  final String id;
  final String email;
  final AppRole role;
  final String? fullName;

  bool get hasAssignedRole => role != AppRole.unknown;
}
