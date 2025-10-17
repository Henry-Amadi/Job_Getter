import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final user = FirebaseAuth.instance.currentUser;
  double balance = 0.0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    if (user != null) {
      final walletDoc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user!.uid)
          .get();

      if (walletDoc.exists) {
        setState(() {
          balance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();
        });

        final transactionsQuery = await FirebaseFirestore.instance
            .collection('wallets')
            .doc(user!.uid)
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        setState(() {
          transactions = transactionsQuery.docs
              .map((doc) => doc.data())
              .toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001C32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('My Wallet'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Card(
                  color: Colors.blue,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.add,
                      label: 'Add Money',
                      onTap: () {
                        // TODO: Implement add money functionality
                      },
                    ),
                    _buildQuickActionButton(
                      icon: Icons.send,
                      label: 'Send',
                      onTap: () {
                        // TODO: Implement send money functionality
                      },
                    ),
                    _buildQuickActionButton(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () {
                        // TODO: Implement full history view
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Recent Transactions
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (transactions.isEmpty)
                  Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return Card(
                        color: Colors.white.withOpacity(0.1),
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            transaction['type'] == 'credit'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: transaction['type'] == 'credit'
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                            transaction['description'] ?? 'Transaction',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            transaction['timestamp']?.toDate()?.toString() ??
                                'Unknown date',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: Text(
                            '${transaction['type'] == 'credit' ? '+' : '-'}\$${transaction['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: transaction['type'] == 'credit'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
