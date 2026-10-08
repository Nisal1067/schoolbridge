import 'package:cloud_firestore/cloud_firestore.dart';

class UserItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'Student', 'Teacher', 'Admin', 'Parent'
  final String gradeOrClass; // e.g. 'Grade 10-A', 'Mathematics', 'Administration'
  final String status; // 'Active', 'Inactive'
  final String joinedDate;
  final List<String> parentIds;
  final String address;
  final String homePhone;
  final String dob;
  final String gender;
  final String admissionNo;
  final String nic;
  final String occupation;
  final List<String> subjects;
  final String qualification;

  const UserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.gradeOrClass,
    this.status = 'Active',
    required this.joinedDate,
    this.parentIds = const [],
    this.address = '',
    this.homePhone = '',
    this.dob = '',
    this.gender = '',
    this.admissionNo = '',
    this.nic = '',
    this.occupation = '',
    this.subjects = const [],
    this.qualification = '',
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String get subtitle {
    if (gradeOrClass.isNotEmpty) {
      return '$role • $gradeOrClass';
    }
    return role;
  }

  String get subjectsFormatted => subjects.join(', ');

  UserItem copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? gradeOrClass,
    String? status,
    String? joinedDate,
    List<String>? parentIds,
    String? address,
    String? homePhone,
    String? dob,
    String? gender,
    String? admissionNo,
    String? nic,
    String? occupation,
    List<String>? subjects,
    String? qualification,
  }) {
    return UserItem(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gradeOrClass: gradeOrClass ?? this.gradeOrClass,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      parentIds: parentIds ?? this.parentIds,
      address: address ?? this.address,
      homePhone: homePhone ?? this.homePhone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      admissionNo: admissionNo ?? this.admissionNo,
      nic: nic ?? this.nic,
      occupation: occupation ?? this.occupation,
      subjects: subjects ?? this.subjects,
      qualification: qualification ?? this.qualification,
    );
  }

  Map<String, dynamic> toMap() {
    final roleLower = role.trim().toLowerCase();
    final cleanRole = roleLower == 'staff' ? 'admin' : roleLower;
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': cleanRole,
      'gradeOrClass': gradeOrClass,
      'class': gradeOrClass,
      'classId': gradeOrClass,
      'schoolId': 'school01',
      'active': status.toLowerCase() == 'active',
      'status': status,
      'joinedDate': joinedDate,
      'parentIds': parentIds,
      'address': address,
      'homePhone': homePhone,
      'dob': dob,
      'gender': gender,
      'admissionNo': admissionNo,
      'employeeId': admissionNo,
      'nic': nic,
      'occupation': occupation,
      'subjects': subjects,
      'subject': subjectsFormatted,
      'qualification': qualification,
      'qualifications': qualification,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserItem.fromMap(Map<String, dynamic> map, String id) {
    String parsedRole = 'Student';
    if (map['role'] != null) {
      final r = map['role'].toString().trim().toLowerCase();
      if (r == 'admin' || r == 'staff' || r == 'administrator') {
        parsedRole = 'Admin';
      } else if (r == 'teacher' || r == 'faculty') {
        parsedRole = 'Teacher';
      } else if (r == 'parent' || r == 'guardian') {
        parsedRole = 'Parent';
      } else if (r == 'student') {
        parsedRole = 'Student';
      } else if (r.isNotEmpty) {
        parsedRole = r[0].toUpperCase() + r.substring(1);
      }
    }

    String parsedStatus = 'Active';
    if (map['active'] != null) {
      parsedStatus = map['active'] == true ? 'Active' : 'Inactive';
    } else if (map['status'] != null) {
      parsedStatus = map['status'].toString();
    }

    String parsedGrade = map['gradeOrClass'] ??
        map['classId'] ??
        map['class'] ??
        (map['grade'] != null ? 'Grade ${map['grade']}' : '') ??
        map['department'] ??
        '';

    List<String> parsedParentIds = [];
    if (map['parentIds'] != null) {
      if (map['parentIds'] is List) {
        parsedParentIds = List<String>.from(map['parentIds']);
      }
    }

    List<String> parsedSubjects = [];
    if (map['subjects'] != null) {
      if (map['subjects'] is List) {
        parsedSubjects = (map['subjects'] as List).map((e) => e.toString()).toList();
      } else if (map['subjects'] is String && (map['subjects'] as String).isNotEmpty) {
        parsedSubjects = (map['subjects'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } else if (map['subject'] != null && map['subject'].toString().isNotEmpty) {
      parsedSubjects = [map['subject'].toString()];
    }

    final parsedQualification = (map['qualification'] ??
            map['qualifications'] ??
            map['designation'] ??
            '')
        .toString();

    final parsedAdmissionNo = (map['admissionNo'] ??
            map['employeeId'] ??
            map['indexNo'] ??
            '')
        .toString();

    return UserItem(
      id: id,
      name: map['name'] ?? map['fullName'] ?? 'User',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: parsedRole,
      gradeOrClass: parsedGrade,
      status: parsedStatus,
      joinedDate: map['joinedDate'] ?? 'Jan 15, 2026',
      parentIds: parsedParentIds,
      address: map['address']?.toString() ?? '',
      homePhone: (map['homePhone'] ?? map['landline'] ?? '')?.toString() ?? '',
      dob: (map['dob'] ?? map['dateOfBirth'] ?? '')?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      admissionNo: parsedAdmissionNo,
      nic: map['nic']?.toString() ?? '',
      occupation: map['occupation']?.toString() ?? '',
      subjects: parsedSubjects,
      qualification: parsedQualification,
    );
  }
}
