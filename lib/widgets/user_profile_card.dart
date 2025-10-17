import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final DateTime? lastUpdated;

  const UserProfileCard({
    Key? key,
    required this.userId,
    required this.userData,
    this.lastUpdated,
  }) : super(key: key);

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile picture
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: userData['photoUrl'] != null
                      ? NetworkImage(userData['photoUrl'])
                      : null,
                  child: userData['photoUrl'] == null
                      ? Icon(Icons.person, size: 40, color: Colors.white70)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? 'No Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (userData['title'] != null)
                        Text(
                          userData['title'],
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white24, height: 32),

            // Contact Information
            _buildProfileItem(Icons.email, 'Email', userData['email'] ?? ''),
            _buildProfileItem(Icons.phone, 'Phone', userData['phone'] ?? ''),
            _buildProfileItem(Icons.location_on, 'Location', userData['location'] ?? ''),

            // Professional Information
            if (userData['skills'] != null && (userData['skills'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skills',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (userData['skills'] as List).map<Widget>((skill) {
                        return Chip(
                          label: Text(
                            skill,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // Bio/About
            if (userData['bio'] != null && userData['bio'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      userData['bio'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Last Updated
            if (lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Last updated: ${lastUpdated!.toLocal().toString().split('.')[0]}',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
