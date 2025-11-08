import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../services/balance_service.dart';
import 'add_participant_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _trip = StorageService().getTrip(widget.tripId);
    _expenses = StorageService().listExpenses(widget.tripId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Trip not found')),
      );
    }
    final me = StorageService().currentUser!;
    final balanceService = BalanceService();
    final net = balanceService.computeNetBalances(_expenses);
    final settlements = balanceService.computeSettlements(net);
    final summary = StorageService().getExpenseSummary(trip.tripId);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddParticipantScreen(tripId: trip.tripId),
                ),
              );
              if (result == true) {
                _load(); // Refresh the trip data
              }
            },
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Participant',
          ),
          if (me.userId == trip.adminUserId)
            IconButton(
              onPressed: () async {
                await StorageService().deleteTrip(trip.tripId);
                if (!mounted) return;
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Delete trip',
            ),
        ],
      ),
      body: Column(
        children: [
          // Trip info and summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join Code',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          trip.joinCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Duration',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${trip.startDate.toLocal().toString().split(' ').first} - ${trip.endDate.toLocal().toString().split(' ').first}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Expense summary
                Row(
                  children: [
                    Expanded(
                      child: _buildClickableSummaryCard(
                        'Total Spent',
                        '${summary['totalAmount'].toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.blue,
                        () => _showSummaryDetails('Total Spent', summary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClickableSummaryCard(
                        'Expenses',
                        '${summary['totalExpenses']}',
                        Icons.receipt,
                        Colors.green,
                        () => _showSummaryDetails('Expenses', summary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClickableSummaryCard(
                        'Average',
                        '${summary['averageAmount'].toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.orange,
                        () => _showSummaryDetails('Average', summary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Expenses list
          Expanded(
            child: _expenses.isEmpty
                ? _buildEmptyExpenses()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final e = _expenses[index];
                      final isPayer = e.paidByUserId == me.userId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              e.currency,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            '${e.currency} ${e.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Paid by ${StorageService().getUserDisplayName(e.paidByUserId) ?? 'Unknown'} · Split among ${e.participantUserIds.length}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: isPayer || me.userId == trip.adminUserId
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await StorageService().deleteExpense(trip.tripId, e.expenseId);
                                    _load();
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          // Who owes whom section - fixed with proper padding
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Settlements',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (settlements.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'All Settled!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No outstanding balances',
                          style: TextStyle(color: Colors.green[600], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: settlements.map((s) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue[100],
                              child: Icon(Icons.person, color: Colors.blue[600], size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${StorageService().getUserDisplayName(s.fromUserId) ?? s.fromUserId}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'owes',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  Text(
                                    '${StorageService().getUserDisplayName(s.toUserId) ?? s.toUserId}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                '₹${s.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16, // Fix overlap
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.pushNamed(context, '/addExpense', arguments: trip.tripId);
            _load();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ),
    );
  }

  Widget _buildClickableSummaryCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Icon(Icons.info_outline, color: color, size: 12),
          ],
        ),
      ),
    );
  }

  void _showSummaryDetails(String type, Map<String, dynamic> summary) {
    String content = '';
    String title = '';
    
    switch (type) {
      case 'Total Spent':
        title = 'Total Spent Details';
        content = 'Total amount spent across all expenses: ₹${summary['totalAmount'].toStringAsFixed(2)}\n\n'
            'This includes all expenses added to this trip.';
        break;
      case 'Expenses':
        title = 'Expenses Details';
        content = 'Total number of expenses: ${summary['totalExpenses']}\n\n'
            'Each expense is split among participants and tracked for balance calculations.';
        break;
      case 'Average':
        title = 'Average Expense Details';
        content = 'Average amount per expense: ₹${summary['averageAmount'].toStringAsFixed(2)}\n\n'
            'This is calculated by dividing total spent by number of expenses.';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first expense to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


