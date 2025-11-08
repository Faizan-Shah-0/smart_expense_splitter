import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../models/trip.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: '₹');
  final _notes = TextEditingController();
  String? _paidBy;
  final _selected = <String>{};
  bool _saving = false;

  late final String tripId;
  Trip? _trip;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tripId = ModalRoute.of(context)!.settings.arguments as String;
    _trip = StorageService().getTrip(tripId);
    if (_trip != null) {
      _paidBy ??= StorageService().currentUser?.userId ?? _trip!.adminUserId;
      _selected.addAll(_trip!.participantUserIds);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0 || _paidBy == null || _trip == null) return;
    setState(() => _saving = true);
    await StorageService().addExpense(
      tripId: tripId,
      amount: amount,
      currency: _currency.text.trim().isEmpty ? '₹' : _currency.text.trim(),
      paidByUserId: _paidBy!,
      participantUserIds: _selected.toList(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    if (trip == null) {
      return const Scaffold(body: Center(child: Text('Trip not found')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 80, // Extra space for FAB
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency symbol',
                        prefixIcon: Icon(Icons.currency_exchange),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paidBy,
                      decoration: const InputDecoration(
                        labelText: 'Paid by',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: trip.participantUserIds
                          .map((u) {
                            final name = StorageService().getUserDisplayName(u) ?? 'Unknown User';
                            return DropdownMenuItem(
                              value: u,
                              child: Text(name),
                            );
                          })
                          .toList(),
                      onChanged: (v) => setState(() => _paidBy = v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Participants',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final u in trip.participantUserIds)
                          FilterChip(
                            label: Text(StorageService().getUserDisplayName(u) ?? 'Unknown'),
                            selected: _selected.contains(u),
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _selected.add(u);
                                } else {
                                  _selected.remove(u);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


