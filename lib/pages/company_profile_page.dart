import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyProfilePage extends StatefulWidget {
  @override
  _CompanyProfilePageState createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _hasProfile = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchCompanyProfile();
  }

  Future<void> _fetchCompanyProfile() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Fetching profile for user: ${user.uid}');
        
        // First try to fetch by user ID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('companyID')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists) {
          print('Found profile by user ID');
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _addressController.text = data['address'] ?? '';
            _emailController.text = data['email'] ?? '';
            _industryController.text = data['industry'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _hasProfile = true;
            _lastUpdated = (data['updatedAt'] as Timestamp?)?.toDate();
          });
        } else {
          // Try to find old profile with generated ID
          print('No profile found by user ID, checking for old profile...');
          final oldProfiles = await FirebaseFirestore.instance
              .collection('companyID')
              .where('userId', isEqualTo: user.uid)
              .get();
              
          if (oldProfiles.docs.isNotEmpty) {
            print('Found old profile, migrating to new format...');
            final oldData = oldProfiles.docs.first.data();
            
            // Migrate old profile to new format using user ID
            await FirebaseFirestore.instance
                .collection('companyID')
                .doc(user.uid)
                .set(oldData);
                
            // Delete old profile
            await FirebaseFirestore.instance
                .collection('companyID')
                .doc(oldProfiles.docs.first.id)
                .delete();
                
            setState(() {
              _nameController.text = oldData['name'] ?? '';
              _addressController.text = oldData['address'] ?? '';
              _emailController.text = oldData['email'] ?? '';
              _industryController.text = oldData['industry'] ?? '';
              _phoneController.text = oldData['phone'] ?? '';
              _hasProfile = true;
            });
          } else {
            print('No existing profile found');
            setState(() => _hasProfile = false);
          }
        }
      } else {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to manage your company profile'))
        );
      }
    } catch (e) {
      print('Error fetching profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCompanyProfile() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Saving profile for user: ${user.uid}');
        
        if (_nameController.text.trim().isEmpty) {
          throw 'Company name is required';
        }

        final data = {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'email': _emailController.text.trim(),
          'industry': _industryController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'createdAt': _hasProfile ? FieldValue.serverTimestamp() : null,
        };

        print('Saving data to document ID: ${user.uid}');
        
        // Always use the user's ID as the document ID
        await FirebaseFirestore.instance
            .collection('companyID')
            .doc(user.uid)
            .set(data, SetOptions(merge: true));

        print('Profile saved successfully');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hasProfile ? 'Profile updated successfully!' : 'Profile created successfully!'))
        );
        
        setState(() => _hasProfile = true);
      } else {
        throw 'No user logged in';
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProfile() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF001C32),
          title: Text(
            'Delete Profile',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete your company profile? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('companyID')
              .doc(user.uid)
              .delete();

          setState(() {
            _hasProfile = false;
            _nameController.clear();
            _addressController.clear();
            _emailController.clear();
            _industryController.clear();
            _phoneController.clear();
            _lastUpdated = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile deleted successfully'))
          );
        }
      } catch (e) {
        print('Error deleting profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting profile: $e'))
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _hasProfile ? 'Edit Company Profile' : 'Create Company Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF001C32),
        child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Section
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _nameController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Company Name',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.business, color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 15),
                            TextField(
                              controller: _addressController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Address',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.location_on, color: Colors.white70),
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
                              controller: _industryController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Industry',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                prefixIcon: Icon(Icons.category, color: Colors.white70),
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
                            SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: _saveCompanyProfile,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  child: Text(
                                    _hasProfile ? 'Update Profile' : 'Create Profile',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Profile View Section
                    if (_hasProfile) ...[
                      SizedBox(height: 30),
                      Card(
                        color: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _nameController.text.isNotEmpty 
                                          ? _nameController.text[0].toUpperCase()
                                          : '?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nameController.text,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_lastUpdated != null)
                                          Text(
                                            'Last updated: ${_lastUpdated!.toLocal().toString().split('.')[0]}',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),
                              _buildProfileItem(Icons.business, 'Company Name', _nameController.text),
                              _buildProfileItem(Icons.location_on, 'Address', _addressController.text),
                              _buildProfileItem(Icons.email, 'Email', _emailController.text),
                              _buildProfileItem(Icons.category, 'Industry', _industryController.text),
                              _buildProfileItem(Icons.phone, 'Phone', _phoneController.text),
                              SizedBox(height: 20),
                              Divider(color: Colors.white24),
                              SizedBox(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _deleteProfile,
                                  icon: Icon(Icons.delete_outline, color: Colors.white),
                                  label: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      'Delete Profile',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    minimumSize: Size(200, 50), // Match update button size
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    if (value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
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
}
