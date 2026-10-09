import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../attendance/services/attendance_service.dart';
import 'profile_photo_avatar.dart';

class StudentProfileScreen extends StatefulWidget {
  final bool isTab;

  const StudentProfileScreen({super.key, this.isTab = false});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _service = AttendanceService();
  late Future<Map<String, dynamic>> _data = _load();

  Future<Map<String, dynamic>> _load() async {
    final profile = await _service.profile();
    final students = await _service.linkedStudents();
    return {...profile, if (students.isNotEmpty) ...students.first};
  }

  String _value(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isTab
          ? null
          : AppBar(
              title: const Text('Student Profile'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _data = _load()),
                child: const Text('Could not load profile. Retry'),
              ),
            );
          }

          final data = snapshot.data!;
          final name = _value(data, ['name']).isEmpty
              ? 'Student'
              : _value(data, ['name']);
          final initials = name
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: [
                Center(
                  child: ProfilePhotoAvatar(
                    initials: initials.isEmpty ? 'S' : initials,
                    onChanged: () => setState(() => _data = _load()),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Student Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                _section('Academic Details', Icons.school_outlined, [
                  _detail(
                    'Class',
                    _value(data, ['gradeOrClass', 'classId', 'class', 'grade']),
                  ),
                  _detail(
                    'Admission No.',
                    _value(data, ['admissionNo', 'indexNo']),
                  ),
                ]),
                _section('Personal Details', Icons.person_outline_rounded, [
                  _detail(
                    'Date of Birth',
                    _value(data, ['dob', 'dateOfBirth']),
                  ),
                  _detail('Gender', _value(data, ['gender'])),
                  _detail('Address', _value(data, ['address'])),
                ]),
                _section('Contact Details', Icons.contact_mail_outlined, [
                  _detail('Email', _value(data, ['email'])),
                  _detail('Phone', _value(data, ['phone', 'mobile'])),
                ]),
                if (widget.isTab)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
