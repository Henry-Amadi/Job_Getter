import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:job_getter_application/pages/notifications_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  List<DocumentSnapshot> _jobs = [];
  String? _error;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _checkUnreadNotifications();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all active jobs without sorting
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('job_posting')
          .where('status', isEqualTo: 'active')
          .get();

      // Sort jobs in memory
      final sortedJobs = jobsSnapshot.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['created_at'] as Timestamp).toDate();
          final bTime = (b.data()['created_at'] as Timestamp).toDate();
          return bTime.compareTo(aTime); // Descending order (newest first)
        });

      setState(() {
        _jobs = sortedJobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get unread notifications count
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('user_id', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      setState(() {
        _unreadNotifications = notificationsSnapshot.docs.length;
      });
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _showToast('Successfully signed out');
    } catch (e) {
      _showToast('Error signing out');
    }
  }

  Future<void> _applyForJob(String jobId, Map<String, dynamic> jobData) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showToast('Please log in to apply');
        return;
      }

      // Check if user has already applied
      final applicationDoc = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('job_id', isEqualTo: jobId)
          .where('applicant_id', isEqualTo: user.uid)
          .get();

      if (applicationDoc.docs.isNotEmpty) {
        _showToast('You have already applied for this job');
        return;
      }

      // Create application
      await FirebaseFirestore.instance.collection('job_applications').add({
        'job_id': jobId,
        'job_title': jobData['job_title'],
        'company_id': jobData['company_id'],
        'company_name': jobData['company_name'],
        'applicant_id': user.uid,
        'applicant_email': user.email,
        'status': 'pending',
        'applied_at': FieldValue.serverTimestamp(),
      });

      // Increment applications count
      await FirebaseFirestore.instance
          .collection('job_posting')
          .doc(jobId)
          .update({
        'applications_count': FieldValue.increment(1),
      });

      _showToast('Successfully applied for the job!');
    } catch (e) {
      _showToast('Error applying for job: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) { // Wallet tab
      Navigator.pushNamed(context, '/wallet');
      return;
    }

    if (index == 2) { // Notifications tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationsPage(),
        ),
      ).then((_) => _checkUnreadNotifications());
      return;
    }

    if (index == 3) { // Profile tab
      Navigator.pushNamed(context, '/user-profile');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildJobCard(DocumentSnapshot job) {
    final data = job.data() as Map<String, dynamic>;
    final createdAt = (data['created_at'] as Timestamp).toDate();
    final price = data['job_price']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['job_title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['company_name'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$$price',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data['job_tag'] ?? '',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data['job_description'] ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Posted ${DateFormat('MMM d, yyyy').format(createdAt)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _applyForJob(job.id, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Apply Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF001C32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Job Getter',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadJobs,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: signOut,
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Text(
                'Welcome back, ${user?.email ?? 'User'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // Jobs list section
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadJobs,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _jobs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.work_off,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No jobs available',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadJobs,
                                child: ListView.builder(
                                  itemCount: _jobs.length,
                                  itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF001C32),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        _unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}