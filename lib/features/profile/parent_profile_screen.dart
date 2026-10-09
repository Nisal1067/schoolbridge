import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_photo_avatar.dart';

class ParentProfileScreen extends StatefulWidget {
  final bool isTab;
  const ParentProfileScreen({super.key, this.isTab = false});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  late Future<Map<String, dynamic>> _data = _load();

  Future<Map<String, dynamic>> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final profileSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!profileSnap.exists) throw Exception('Profile not found');
    
    // Parent users usually have their uids in the 'parentIds' array inside the students collection.
    final studentsSnap = await FirebaseFirestore.instance
        .collection('students')
        .where('schoolId', isEqualTo: profileSnap.data()?['schoolId'])
        .where('parentIds', arrayContains: uid)
        .get();
    final students = studentsSnap.docs.map((d) => d.data()).toList();
    
    return {...profileSnap.data() as Map<String, dynamic>, 'students': students};
  }

  Widget _section(String title, Widget content, {IconData? icon}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF1E40AF)),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        if (icon != null)
          const Divider(height: 24, color: Color(0xFFF1F5F9))
        else
          const SizedBox(height: 12),
        content,
      ],
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value.isEmpty ? 'Not provided' : value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isTab ? null : AppBar(
        title: const Text('Parent Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          final name = (data['name'] ?? 'Parent Name').toString();
          final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';
          final email = (data['email'] ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          final students = data['students'] as List<dynamic>;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: [
                Center(
                  child: ProfilePhotoAvatar(
                    initials: initials,
                    radius: 42,
                    onChanged: () => setState(() => _data = _load()),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Parent Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                
                _section(
                  'Contact Details',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detail('Email', email),
                      _detail('Phone', phone),
                    ],
                  ),
                  icon: Icons.person_outline_rounded,
                ),

                _section(
                  'Linked Students',
                  students.isEmpty 
                  ? const Text('No students linked to this account.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
                  : Column(
                      children: students.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.school, size: 16, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(s['name'] ?? 'Unknown Student', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                          ],
                        ),
                      )).toList(),
                    ),
                  icon: Icons.family_restroom_rounded,
                ),

                const SizedBox(height: 20),
                
                if (widget.isTab)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      label: const Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
}
