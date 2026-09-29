import 'package:flutter/material.dart';

import '../../models/user_role.dart';

class UserCommunicationScreen
    extends StatelessWidget {
  final UserRole role;

  const UserCommunicationScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.admin) {
      return const UserManagementScreen();
    }

    return const CommunicationScreen();
  }
}

class UserManagementScreen
    extends StatelessWidget {
  const UserManagementScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('User Management'),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(
          Icons.person_add,
        ),
        label:
            const Text('Add User'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title:
                  Text('Nadeesha Silva'),
              subtitle:
                  Text('Teacher'),
              trailing:
                  Icon(Icons.more_vert),
            ),
          ),

          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title:
                  Text('Kasun Silva'),
              subtitle:
                  Text('Parent'),
              trailing:
                  Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunicationScreen
    extends StatelessWidget {
  const CommunicationScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Messages'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title:
                  Text('Mrs. Nadeesha'),
              subtitle:
                  Text('Mathematics Teacher'),
              trailing:
                  Icon(Icons.chevron_right),
            ),
          ),

          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title:
                  Text('Mr. Jayasinghe'),
              subtitle:
                  Text('Science Teacher'),
              trailing:
                  Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}