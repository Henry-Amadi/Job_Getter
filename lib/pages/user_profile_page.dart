import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/user_profile_card.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  bool _isLoading = true;
  bool _hasProfile = false;
  DateTime? _lastUpdated;
  String? _photoUrl;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _locationController.text = data['location'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _titleController.text = data['title'] ?? '';
            _photoUrl = data['photoUrl'];
            _skills = List<String>.from(data['skills'] ?? []);
            _hasProfile = true;
            _lastUpdated = (data['updatedAt'] as Timestamp?)?.toDate();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to manage your profile'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserProfile() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_nameController.text.trim().isEmpty) {
          throw 'Name is required';
        }

        final data = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'bio': _bioController.text.trim(),
          'title': _titleController.text.trim(),
          'photoUrl': _photoUrl,
          'skills': _skills,
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'createdAt': _hasProfile ? FieldValue.serverTimestamp() : null,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(data, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hasProfile ? 'Profile updated!' : 'Profile created!'))
        );
        
        setState(() => _hasProfile = true);
        _fetchUserProfile(); // Refresh the profile data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      setState(() => _isLoading = true);

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_photos')
            .child('${user.uid}.jpg');

        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();

        setState(() => _photoUrl = url);
        await _saveUserProfile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addSkill(String skill) {
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001C32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          _hasProfile ? 'Edit Profile' : 'Create Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Preview Card
                    if (_hasProfile)
                      UserProfileCard(
                        userId: FirebaseAuth.instance.currentUser!.uid,
                        userData: {
                          'name': _nameController.text,
                          'email': _emailController.text,
                          'phone': _phoneController.text,
                          'location': _locationController.text,
                          'bio': _bioController.text,
                          'title': _titleController.text,
                          'photoUrl': _photoUrl,
                          'skills': _skills,
                        },
                        lastUpdated: _lastUpdated,
                      ),

                    SizedBox(height: 20),

                    // Edit Form
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),

                            // Profile Picture
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _photoUrl != null
                                        ? NetworkImage(_photoUrl!)
                                        : null,
                                    child: _photoUrl == null
                                        ? Icon(Icons.person, size: 50)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      radius: 18,
                                      child: IconButton(
                                        icon: Icon(Icons.camera_alt, size: 18),
                                        onPressed: _uploadImage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),

                            // Form Fields
                            TextField(
                              controller: _nameController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.person, color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 15),

                            TextField(
                              controller: _titleController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Professional Title',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.work, color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 15),

                            TextField(
                              controller: _emailController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.email, color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 15),

                            TextField(
                              controller: _phoneController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.phone, color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 15),

                            TextField(
                              controller: _locationController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Location',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.location_on, color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 15),

                            // Skills
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Skills',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _skills.map((skill) {
                                    return Chip(
                                      label: Text(skill),
                                      onDeleted: () => _removeSkill(skill),
                                      backgroundColor: Colors.blue.withOpacity(0.3),
                                    );
                                  }).toList(),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _skillsController,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Add a skill',
                                          hintStyle: TextStyle(color: Colors.white54),
                                          border: OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white30),
                                          ),
                                        ),
                                        onSubmitted: _addSkill,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add, color: Colors.white),
                                      onPressed: () => _addSkill(_skillsController.text),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 15),

                            TextField(
                              controller: _bioController,
                              style: TextStyle(color: Colors.white),
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Bio',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.description, color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveUserProfile,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  _hasProfile ? 'Update Profile' : 'Create Profile',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
