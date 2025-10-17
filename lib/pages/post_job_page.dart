import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class PostJobPage extends StatefulWidget {
  const PostJobPage({super.key});

  @override
  State<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;

  Future<Map<String, dynamic>?> _getCompanyProfile(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('companyID')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching company profile: $e');
      return null;
    }
  }

  Future<void> _postJob() async {
    if (!mounted) return;

    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _tagController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Please log in to post a job';
      }

      // Get company profile
      final companyProfile = await _getCompanyProfile(user.uid);
      if (companyProfile == null) {
        throw 'Please create a company profile before posting a job';
      }

      // Create job posting with company information
      DocumentReference newJobRef = await FirebaseFirestore.instance.collection('job_posting').add({
        'job_title': _titleController.text.trim(),
        'job_tag': _tagController.text.trim(),
        'job_price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'job_description': _descriptionController.text.trim(),
        'image_url': _imageUrl,
        // Company and tracking information
        'company_id': user.uid,
        'company_name': companyProfile['name'],
        'company_email': companyProfile['email'],
        'company_phone': companyProfile['phone'],
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'applications_count': 0,
      });

      // Update company's jobs collection for easy tracking
      await FirebaseFirestore.instance
          .collection('companyID')
          .doc(user.uid)
          .collection('jobs')
          .doc(newJobRef.id)
          .set({
            'job_id': newJobRef.id,
            'job_title': _titleController.text.trim(),
            'status': 'active',
            'created_at': FieldValue.serverTimestamp(),
            'applications_count': 0,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job posted successfully!')),
      );

      // Clear the fields after posting
      _titleController.clear();
      _descriptionController.clear();
      _tagController.clear();
      _priceController.clear();
      setState(() {
        _imageUrl = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageUrl = pickedFile.path; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001C32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Post Job',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Job Title',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        prefixIcon: Icon(Icons.work, color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _tagController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Job Tag',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        prefixIcon: Icon(Icons.tag, color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _priceController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Job Price',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.white70),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Job Description',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        prefixIcon: Icon(Icons.description, color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image, color: Colors.white),
                      label: Text('Pick Image', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _postJob,
                      icon: Icon(Icons.post_add, color: Colors.white),
                      label: Text('Post Job', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: Size(200, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}