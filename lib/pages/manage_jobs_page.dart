import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManageJobsPage extends StatefulWidget {
  @override
  _ManageJobsPageState createState() => _ManageJobsPageState();
}

class _ManageJobsPageState extends State<ManageJobsPage> {
  bool _isLoading = true;
  List<DocumentSnapshot> _jobs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Please log in to view your jobs';
      }

      // First get jobs without sorting
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('job_posting')
          .where('company_id', isEqualTo: user.uid)
          .get();

      // Sort jobs in memory
      final sortedJobs = jobsSnapshot.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['created_at'] as Timestamp).toDate();
          final bTime = (b.data()['created_at'] as Timestamp).toDate();
          return bTime.compareTo(aTime); // Descending order
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

  Future<void> _toggleJobStatus(String jobId, bool isActive) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update main job posting
      await FirebaseFirestore.instance
          .collection('job_posting')
          .doc(jobId)
          .update({
        'status': isActive ? 'active' : 'inactive',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update company's job reference
      await FirebaseFirestore.instance
          .collection('companyID')
          .doc(user.uid)
          .collection('jobs')
          .doc(jobId)
          .update({
        'status': isActive ? 'active' : 'inactive',
      });

      // Refresh jobs list
      _loadJobs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating job status: $e')),
      );
    }
  }

  Future<void> _deleteJob(String jobId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF001C32),
          title: Text(
            'Delete Job',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete this job posting? This action cannot be undone.',
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
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Delete main job posting
        await FirebaseFirestore.instance
            .collection('job_posting')
            .doc(jobId)
            .delete();

        // Delete from company's jobs
        await FirebaseFirestore.instance
            .collection('companyID')
            .doc(user.uid)
            .collection('jobs')
            .doc(jobId)
            .delete();

        // Refresh jobs list
        _loadJobs();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting job: $e')),
        );
      }
    }
  }

  Widget _buildJobCard(DocumentSnapshot job) {
    final data = job.data() as Map<String, dynamic>;
    final isActive = data['status'] == 'active';
    final createdAt = (data['created_at'] as Timestamp).toDate();
    final applicationCount = data['applications_count'] ?? 0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Posted on ${DateFormat('MMM d, yyyy').format(createdAt)}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.tag, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  data['job_tag'] ?? '',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(width: 16),
                Icon(Icons.attach_money, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  '\$${data['job_price']?.toString() ?? '0'}',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(width: 16),
                Icon(Icons.people_outline, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  '$applicationCount applications',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleJobStatus(job.id, !isActive),
                  icon: Icon(
                    isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    color: isActive ? Colors.orange : Colors.green,
                  ),
                  label: Text(
                    isActive ? 'Pause' : 'Activate',
                    style: TextStyle(
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteJob(job.id),
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF001C32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.work_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Manage Jobs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadJobs,
                        child: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                )
              : _jobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_off,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No jobs posted yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your posted jobs will appear here',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _jobs.length,
                      itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
                    ),
    );
  }
}
