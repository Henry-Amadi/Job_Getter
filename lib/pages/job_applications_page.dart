import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class JobApplicationsPage extends StatefulWidget {
  const JobApplicationsPage({super.key});

  @override
  State<JobApplicationsPage> createState() => _JobApplicationsPageState();
}

class _JobApplicationsPageState extends State<JobApplicationsPage> {
  bool _isLoading = true;
  List<DocumentSnapshot> _applications = [];
  String? _error;
  Map<String, DocumentSnapshot> _jobDetails = {};

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Get the company ID for the current user
      final companyDoc = await FirebaseFirestore.instance
          .collection('companyID')
          .doc(user.uid)
          .get();

      if (!companyDoc.exists) {
        setState(() {
          _error = 'Company profile not found';
          _isLoading = false;
        });
        return;
      }

      // Get all applications for jobs posted by this company
      final applicationsSnapshot = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('company_id', isEqualTo: user.uid)
          .get();

      // Sort applications in memory by applied_at timestamp
      final sortedApplications = applicationsSnapshot.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['applied_at'] as Timestamp).toDate();
          final bTime = (b.data()['applied_at'] as Timestamp).toDate();
          return bTime.compareTo(aTime); // Descending order (newest first)
        });

      // Fetch job details for each application
      final jobIds = sortedApplications
          .map((doc) => doc.data()['job_id'] as String)
          .toSet();

      for (final jobId in jobIds) {
        final jobDoc = await FirebaseFirestore.instance
            .collection('job_posting')
            .doc(jobId)
            .get();
        if (jobDoc.exists) {
          _jobDetails[jobId] = jobDoc;
        }
      }

      setState(() {
        _applications = sortedApplications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      // Get the application details first
      final applicationDoc = await FirebaseFirestore.instance
          .collection('job_applications')
          .doc(applicationId)
          .get();

      if (!applicationDoc.exists) {
        throw 'Application not found';
      }

      final applicationData = applicationDoc.data()!;
      final applicantId = applicationData['applicant_id'] as String;
      final jobTitle = applicationData['job_title'] as String;

      // Update application status
      await FirebaseFirestore.instance
          .collection('job_applications')
          .doc(applicationId)
          .update({'status': newStatus});

      // Create notification for the applicant
      await FirebaseFirestore.instance.collection('notifications').add({
        'user_id': applicantId,
        'type': 'application_${newStatus}',
        'title': newStatus == 'approved' ? 'Application Approved!' : 'Application Status Update',
        'message': 'Your application for "${jobTitle}" has been ${newStatus}.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'job_id': applicationData['job_id'],
        'company_name': applicationData['company_name'],
      });

      // Refresh the applications list
      _loadApplications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating application: $e')),
      );
    }
  }

  Widget _buildApplicationCard(DocumentSnapshot application) {
    final data = application.data() as Map<String, dynamic>;
    final appliedAt = (data['applied_at'] as Timestamp).toDate();
    final jobId = data['job_id'] as String;
    final jobData = _jobDetails[jobId]?.data() as Map<String, dynamic>?;
    final status = data['status'] as String;

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

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
                        data['job_title'] ?? 'Unknown Job',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied by: ${data['applicant_email']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (jobData != null) ...[
              Text(
                'Job Details:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                jobData['job_description'] ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applied on ${DateFormat('MMM d, yyyy').format(appliedAt)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                if (status == 'pending')
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _updateApplicationStatus(application.id, 'rejected'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateApplicationStatus(application.id, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
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
          children: const [
            Icon(Icons.people_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Job Applications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadApplications,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                            onPressed: _loadApplications,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _applications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No applications yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadApplications,
                          child: ListView.builder(
                            itemCount: _applications.length,
                            itemBuilder: (context, index) =>
                                _buildApplicationCard(_applications[index]),
                          ),
                        ),
        ),
      ),
    );
  }
}
