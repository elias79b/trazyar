//
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class OwnerUser {
//   const OwnerUser({
//     required this.id,
//     required this.fullName,
//     required this.email,
//     required this.role,
//     required this.isActive,
//     required this.createdAt,
//     this.avatarUrl,
//   });
//
//   final String id;
//   final String fullName;
//   final String email;
//   final String role;
//   final bool isActive;
//   final DateTime createdAt;
//   final String? avatarUrl;
//
//   factory OwnerUser.fromMap(
//       Map<String, dynamic> map,
//       ) {
//     return OwnerUser(
//       id: (map['id'] ?? '').toString(),
//       fullName: (map['full_name'] ?? '').toString(),
//       email: (map['email'] ?? '').toString(),
//       role: (map['role'] ?? 'company_user').toString(),
//       isActive: map['is_active'] == true,
//       createdAt:
//       DateTime.tryParse(
//         (map['created_at'] ?? '').toString(),
//       ) ??
//           DateTime.fromMillisecondsSinceEpoch(0),
//       avatarUrl: map['avatar_url']?.toString(),
//     );
//   }
//
//   String get statusLabel => isActive ? 'فعال' : 'غیرفعال';
//
//   String get roleLabel {
//     return switch (role) {
//       'owner' => 'مدیر کل سیستم',
//       'consultant' => 'مشاور',
//       'company_admin' => 'مدیر شرکت',
//       'accountant' => 'حسابدار',
//       'hr' => 'منابع انسانی',
//       'observer' => 'ناظر',
//       _ => 'کاربر',
//     };
//   }
//
//   String get displayName {
//     final value = fullName.trim();
//     return value.isEmpty ? email : value;
//   }
//
//   String get avatarLetter {
//     final value = displayName.trim();
//     return value.isEmpty ? 'ک' : value[0];
//   }
// }
//
// class OwnerUserUpdateInput {
//   const OwnerUserUpdateInput({
//     required this.fullName,
//     required this.role,
//     required this.isActive,
//     this.companyIds = const [],
//   });
//
//   final String fullName;
//   final String role;
//   final bool isActive;
//
//   /// برای مشاور: چند شرکت
//   /// برای حسابدار: دقیقاً یک شرکت
//   final List<String> companyIds;
// }
//
// class UserInvitationResult {
//   const UserInvitationResult({
//     required this.userId,
//     required this.email,
//   });
//
//   final String userId;
//   final String email;
// }
//
// class CompanyOption {
//   const CompanyOption({
//     required this.id,
//     required this.name,
//   });
//
//   final String id;
//   final String name;
// }
//
// class UsersRepository {
//   UsersRepository()
//       : _client = Supabase.instance.client;
//
//   final SupabaseClient _client;
//
//   // ============================================================
//   // USERS
//   // ============================================================
//
//   Future<List<OwnerUser>> fetchUsers() async {
//     final data = await _client
//         .from('users')
//         .select(
//       'id, full_name, email, role, '
//           'is_active, avatar_url, created_at',
//     )
//         .order(
//       'created_at',
//       ascending: false,
//     );
//
//     return (data as List)
//         .cast<Map<String, dynamic>>()
//         .map(OwnerUser.fromMap)
//         .toList();
//   }
//
//   // ============================================================
//   // UPDATE USER
//   // ============================================================
//
//   Future<void> updateUser({
//     required String id,
//     required OwnerUserUpdateInput input,
//   }) async {
//     await _client
//         .from('users')
//         .update({
//       'full_name': input.fullName.trim(),
//       'role': input.role,
//       'is_active': input.isActive,
//     })
//         .eq('id', id);
//
//     if (input.role == 'consultant') {
//       await syncConsultantCompanies(
//         consultantUserId: id,
//         companyIds: input.companyIds,
//       );
//     }
//   }
//
//   // ============================================================
//   // COMPANIES
//   // ============================================================
//
//   Future<List<CompanyOption>> fetchCompanies() async {
//     final data = await _client
//         .from('companies')
//         .select('id, name')
//         .eq('is_active', true)
//         .order(
//       'name',
//       ascending: true,
//     );
//
//     return (data as List).map(
//           (row) {
//         final map = Map<String, dynamic>.from(row);
//
//         return CompanyOption(
//           id: (map['id'] ?? '').toString(),
//           name: (map['name'] ?? 'بدون نام').toString(),
//         );
//       },
//     ).toList();
//   }
//
//   // ============================================================
//   // شرکت‌های فعلی مشاور
//   // ============================================================
//
//   Future<List<String>> fetchConsultantCompanyIds(
//       String consultantUserId,
//       ) async {
//     final data = await _client
//         .from('consultant_company_assignments')
//         .select('company_id')
//         .eq(
//       'consultant_user_id',
//       consultantUserId,
//     )
//         .eq(
//       'is_active',
//       true,
//     );
//
//     return (data as List)
//         .map(
//           (row) =>
//           (row['company_id'] ?? '').toString(),
//     )
//         .where(
//           (id) => id.isNotEmpty,
//     )
//         .toList();
//   }
//
//   // ============================================================
//   // هماهنگ‌سازی شرکت‌های مشاور
//   // ============================================================
//
//   Future<void> syncConsultantCompanies({
//     required String consultantUserId,
//     required List<String> companyIds,
//   }) async {
//     final uniqueCompanyIds = companyIds
//         .where(
//           (id) => id.trim().isNotEmpty,
//     )
//         .map(
//           (id) => id.trim(),
//     )
//         .toSet()
//         .toList();
//
//     final existingData = await _client
//         .from('consultant_company_assignments')
//         .select(
//       'id, company_id, is_active',
//     )
//         .eq(
//       'consultant_user_id',
//       consultantUserId,
//     );
//
//     final existing = (existingData as List)
//         .map(
//           (row) =>
//       Map<String, dynamic>.from(row),
//     )
//         .toList();
//
//     final existingByCompanyId =
//     <String, Map<String, dynamic>>{};
//
//     for (final row in existing) {
//       final companyId =
//       (row['company_id'] ?? '').toString();
//
//       if (companyId.isNotEmpty) {
//         existingByCompanyId[companyId] = row;
//       }
//     }
//
//     // شرکت‌هایی که باید فعال باشند
//     for (final companyId in uniqueCompanyIds) {
//       final existingRow =
//       existingByCompanyId[companyId];
//
//       if (existingRow == null) {
//         await _client
//             .from(
//           'consultant_company_assignments',
//         )
//             .insert({
//           'consultant_user_id':
//           consultantUserId,
//           'company_id': companyId,
//           'is_active': true,
//         });
//       } else {
//         if (existingRow['is_active'] != true) {
//           await _client
//               .from(
//             'consultant_company_assignments',
//           )
//               .update({
//             'is_active': true,
//             'end_date': null,
//           })
//               .eq(
//             'id',
//             existingRow['id'],
//           );
//         }
//       }
//     }
//
//     // شرکت‌هایی که حذف شده‌اند
//     for (final row in existing) {
//       final companyId =
//       (row['company_id'] ?? '').toString();
//
//       if (companyId.isEmpty) {
//         continue;
//       }
//
//       if (!uniqueCompanyIds.contains(companyId) &&
//           row['is_active'] == true) {
//         await _client
//             .from(
//           'consultant_company_assignments',
//         )
//             .update({
//           'is_active': false,
//           'end_date': DateTime.now()
//               .toUtc()
//               .toIso8601String()
//               .split('T')
//               .first,
//         })
//             .eq(
//           'id',
//           row['id'],
//         );
//       }
//     }
//   }
//
//   // ============================================================
//   // ایجاد دعوت کاربر
//   // ============================================================
//
//   Future<UserInvitationResult> createUserInvitation({
//     required String fullName,
//     required String email,
//     String? phone,
//     required String role,
//     required List<String> companyIds,
//   }) async {
//     final normalizedFullName = fullName.trim();
//     final normalizedEmail = email.trim().toLowerCase();
//
//     // ==========================================================
//     // CONSULTANT
//     // ==========================================================
//
//     if (role == 'consultant') {
//       if (companyIds.isEmpty) {
//         throw Exception(
//           'حداقل یک شرکت باید برای مشاور انتخاب شود.',
//         );
//       }
//
//       final response = await _client.functions.invoke(
//         'smooth-action',
//         body: {
//           'action': 'create_consultant',
//           'fullName': normalizedFullName,
//           'email': normalizedEmail,
//           'phone': phone?.trim(),
//           'role': role,
//           'companyIds': companyIds,
//         },
//       );
//
//       return _parseInvitationResponse(
//         response,
//         'ایجاد مشاور انجام نشد.',
//       );
//     }
//
//     // ==========================================================
//     // ACCOUNTANT
//     // ==========================================================
//
//     if (role == 'accountant') {
//       if (companyIds.length != 1) {
//         throw Exception(
//           'برای حسابدار باید دقیقاً یک شرکت انتخاب شود.',
//         );
//       }
//
//       final response = await _client.functions.invoke(
//         'smooth-action',
//         body: {
//           'action': 'create_accountant',
//           'fullName': normalizedFullName,
//           'email': normalizedEmail,
//           'phone': phone?.trim(),
//           'role': role,
//           'companyIds': companyIds,
//         },
//       );
//
//       return _parseInvitationResponse(
//         response,
//         'ایجاد حسابدار انجام نشد.',
//       );
//     }
//
//     // ==========================================================
//     // سایر نقش‌ها
//     // ==========================================================
//
//     throw Exception(
//       'ایجاد دعوت‌نامه برای نقش «$role» هنوز پیاده‌سازی نشده است.',
//     );
//   }
//
//   // ============================================================
//   // PARSE INVITATION RESPONSE
//   // ============================================================
//
//   UserInvitationResult _parseInvitationResponse(
//       FunctionResponse response,
//       String fallback,
//       ) {
//     final data = response.data;
//
//     if (response.status < 200 ||
//         response.status >= 300) {
//       throw Exception(
//         _extractError(
//           data,
//           'خطا در ایجاد دعوت‌نامه.',
//         ),
//       );
//     }
//
//     if (data is! Map) {
//       throw Exception(
//         'پاسخ نامعتبر از Supabase دریافت شد.',
//       );
//     }
//
//     final result =
//     Map<String, dynamic>.from(data);
//
//     if (result['success'] != true) {
//       throw Exception(
//         _extractError(
//           result,
//           fallback,
//         ),
//       );
//     }
//
//     final userId =
//     result['userId']?.toString();
//
//     final resultEmail =
//     result['email']?.toString();
//
//     if (userId == null ||
//         userId.isEmpty ||
//         resultEmail == null ||
//         resultEmail.isEmpty) {
//       throw Exception(
//         'پاسخ Supabase اطلاعات کاربر را ندارد.',
//       );
//     }
//
//     return UserInvitationResult(
//       userId: userId,
//       email: resultEmail,
//     );
//   }
//
//   // ============================================================
//   // ERROR
//   // ============================================================
//
//   String _extractError(
//       dynamic data,
//       String fallback,
//       ) {
//     if (data is Map) {
//       final error = data['error'];
//
//       if (error != null &&
//           error.toString().trim().isNotEmpty) {
//         return error.toString();
//       }
//
//       final message = data['message'];
//
//       if (message != null &&
//           message.toString().trim().isNotEmpty) {
//         return message.toString();
//       }
//     }
//
//     return fallback;
//   }
// }
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerUser {
  const OwnerUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? avatarUrl;

  String get statusLabel {
    return isActive ? 'فعال' : 'غیرفعال';
  }

  String get displayName {
    final value = fullName.trim();
    return value.isEmpty ? email : value;
  }

  String get avatarLetter {
    final value = displayName.trim();
    return value.isEmpty ? 'ک' : value[0];
  }

  String get roleLabel {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return 'مدیر کل سیستم';
      case 'consultant':
        return 'مشاور';
      case 'company_admin':
        return 'مدیرعامل';
      case 'accountant':
        return 'حسابدار';
      case 'cashier':
        return 'صندوقدار';
      case 'warehouse':
        return 'انباردار';
      case 'hr':
        return 'منابع انسانی';
      case 'observer':
        return 'ناظر';
      default:
        return role.isEmpty ? 'کاربر' : role;
    }
  }

  factory OwnerUser.fromMap(Map<String, dynamic> map) {
    return OwnerUser(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      isActive: map['is_active'] == true,
      createdAt: _parseDate(map['created_at']),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class OwnerUserUpdateInput {
  const OwnerUserUpdateInput({
    required this.fullName,
    required this.role,
    required this.isActive,
    this.companyIds = const [],
  });

  final String fullName;
  final String role;
  final bool isActive;

  /// برای مشاور: چند شرکت
  /// برای حسابدار: دقیقاً یک شرکت
  /// برای مدیرعامل: دقیقاً یک شرکت
  final List<String> companyIds;
}

class UserInvitationResult {
  const UserInvitationResult({
    required this.userId,
    required this.email,
  });

  final String userId;
  final String email;

  factory UserInvitationResult.fromMap(
      Map<String, dynamic> map,
      ) {
    return UserInvitationResult(
      userId: map['userId']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }
}

class CompanyOption {
  const CompanyOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory CompanyOption.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyOption(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }
}

class UsersRepository {
  UsersRepository()
      : _client = Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // USERS
  // ============================================================

  Future<List<OwnerUser>> fetchUsers() async {
    final response = await _client
        .from('users')
        .select(
      'id, full_name, email, role, '
          'is_active, avatar_url, created_at',
    )
        .order(
      'created_at',
      ascending: false,
    );

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(OwnerUser.fromMap)
        .toList();
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  Future<void> updateUser({
    required String id,
    required OwnerUserUpdateInput input,
  }) async {
    await _client
        .from('users')
        .update({
      'full_name': input.fullName.trim(),
      'role': input.role,
      'is_active': input.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id);

    if (input.role == 'consultant') {
      await syncConsultantCompanies(
        consultantUserId: id,
        companyIds: input.companyIds,
      );
    }
  }

  // ============================================================
  // COMPANIES
  // ============================================================

  Future<List<CompanyOption>> fetchCompanies() async {
    final response = await _client
        .from('companies')
        .select('id, name')
        .eq('is_active', true)
        .order(
      'name',
      ascending: true,
    );

    return (response as List)
        .map(
          (row) => CompanyOption.fromMap(
        Map<String, dynamic>.from(row as Map),
      ),
    )
        .toList();
  }

  // ============================================================
  // CONSULTANT COMPANIES
  // ============================================================

  Future<List<String>> fetchConsultantCompanyIds(
      String consultantUserId,
      ) async {
    final response = await _client
        .from('consultant_company_assignments')
        .select('company_id')
        .eq(
      'consultant_user_id',
      consultantUserId,
    )
        .eq(
      'is_active',
      true,
    );

    return (response as List)
        .map(
          (row) => row['company_id']?.toString() ?? '',
    )
        .where(
          (id) => id.isNotEmpty,
    )
        .toList();
  }

  // ============================================================
  // SYNC CONSULTANT COMPANIES
  // ============================================================

  Future<void> syncConsultantCompanies({
    required String consultantUserId,
    required List<String> companyIds,
  }) async {
    final uniqueCompanyIds = companyIds
        .where(
          (id) => id.trim().isNotEmpty,
    )
        .map(
          (id) => id.trim(),
    )
        .toSet()
        .toList();

    final existingData = await _client
        .from('consultant_company_assignments')
        .select(
      'id, company_id, is_active',
    )
        .eq(
      'consultant_user_id',
      consultantUserId,
    );

    final existing = (existingData as List)
        .map(
          (row) => Map<String, dynamic>.from(row),
    )
        .toList();

    final existingByCompanyId =
    <String, Map<String, dynamic>>{};

    for (final row in existing) {
      final companyId =
      (row['company_id'] ?? '').toString();

      if (companyId.isNotEmpty) {
        existingByCompanyId[companyId] = row;
      }
    }

    // شرکت‌هایی که باید فعال باشند
    for (final companyId in uniqueCompanyIds) {
      final existingRow =
      existingByCompanyId[companyId];

      if (existingRow == null) {
        await _client
            .from('consultant_company_assignments')
            .insert({
          'consultant_user_id': consultantUserId,
          'company_id': companyId,
          'is_active': true,
        });
      } else if (existingRow['is_active'] != true) {
        await _client
            .from('consultant_company_assignments')
            .update({
          'is_active': true,
          'end_date': null,
        })
            .eq(
          'id',
          existingRow['id'],
        );
      }
    }

    // شرکت‌هایی که حذف شده‌اند
    for (final row in existing) {
      final companyId =
      (row['company_id'] ?? '').toString();

      if (companyId.isEmpty) {
        continue;
      }

      if (!uniqueCompanyIds.contains(companyId) &&
          row['is_active'] == true) {
        await _client
            .from('consultant_company_assignments')
            .update({
          'is_active': false,
          'end_date': DateTime.now()
              .toUtc()
              .toIso8601String()
              .split('T')
              .first,
        })
            .eq(
          'id',
          row['id'],
        );
      }
    }
  }

  // ============================================================
  // CREATE USER INVITATION
  // ============================================================

  Future<UserInvitationResult> createUserInvitation({
    required String fullName,
    required String email,
    String? phone,
    required String role,
    List<String> companyIds = const [],
  }) async {
    final normalizedFullName = fullName.trim();
    final normalizedEmail =
    email.trim().toLowerCase();
    final normalizedRole =
    role.trim().toLowerCase();

    // ==========================================================
    // CONSULTANT
    // ==========================================================

    if (normalizedRole == 'consultant') {
      if (companyIds.isEmpty) {
        throw Exception(
          'حداقل یک شرکت باید برای مشاور انتخاب شود.',
        );
      }

      final response = await _client.functions.invoke(
        'smooth-action',
        body: {
          'action': 'create_consultant',
          'fullName': normalizedFullName,
          'email': normalizedEmail,
          'phone': phone?.trim(),
          'role': normalizedRole,
          'companyIds': companyIds,
        },
      );

      return _parseInvitationResponse(
        response,
        'ایجاد مشاور انجام نشد.',
      );
    }

    // ==========================================================
    // ACCOUNTANT
    // ==========================================================

    if (normalizedRole == 'accountant') {
      if (companyIds.length != 1) {
        throw Exception(
          'برای حسابدار باید دقیقاً یک شرکت انتخاب شود.',
        );
      }

      final response = await _client.functions.invoke(
        'smooth-action',
        body: {
          'action': 'create_accountant',
          'fullName': normalizedFullName,
          'email': normalizedEmail,
          'phone': phone?.trim(),
          'role': normalizedRole,
          'companyIds': companyIds,
        },
      );

      return _parseInvitationResponse(
        response,
        'ایجاد حسابدار انجام نشد.',
      );
    }

    // ==========================================================
    // COMPANY ADMIN / CEO
    // ==========================================================

    if (normalizedRole == 'company_admin') {
      if (companyIds.length != 1) {
        throw Exception(
          'برای مدیرعامل باید دقیقاً یک شرکت انتخاب شود.',
        );
      }

      final response = await _client.functions.invoke(
        'smooth-action',
        body: {
          'action': 'create_company_admin',
          'fullName': normalizedFullName,
          'email': normalizedEmail,
          'phone': phone?.trim(),
          'role': normalizedRole,
          'companyIds': companyIds,
        },
      );

      return _parseInvitationResponse(
        response,
        'ایجاد مدیرعامل انجام نشد.',
      );
    }

    // ==========================================================
    // OTHER ROLES
    // ==========================================================

    throw Exception(
      'ایجاد دعوت‌نامه برای نقش «$role» هنوز پیاده‌سازی نشده است.',
    );
  }

  // ============================================================
  // PARSE INVITATION RESPONSE
  // ============================================================

  UserInvitationResult _parseInvitationResponse(
      FunctionResponse response,
      String fallback,
      ) {
    final data = response.data;

    if (response.status < 200 ||
        response.status >= 300) {
      throw Exception(
        _extractError(
          data,
          'خطا در ایجاد دعوت‌نامه.',
        ),
      );
    }

    if (data is! Map) {
      throw Exception(
        'پاسخ نامعتبر از Supabase دریافت شد.',
      );
    }

    final result =
    Map<String, dynamic>.from(data);

    if (result['success'] != true) {
      throw Exception(
        _extractError(
          result,
          fallback,
        ),
      );
    }

    final userId =
    result['userId']?.toString();

    final resultEmail =
    result['email']?.toString();

    if (userId == null ||
        userId.isEmpty ||
        resultEmail == null ||
        resultEmail.isEmpty) {
      throw Exception(
        'پاسخ Supabase اطلاعات کاربر را ندارد.',
      );
    }

    return UserInvitationResult(
      userId: userId,
      email: resultEmail,
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _extractError(
      dynamic data,
      String fallback,
      ) {
    if (data is Map) {
      final error = data['error'];

      if (error != null &&
          error.toString().trim().isNotEmpty) {
        return error.toString();
      }

      final message = data['message'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return fallback;
  }
}
