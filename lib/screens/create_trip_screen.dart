import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _title = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  final _participants = TextEditingController();
  final _searchController = TextEditingController();
  bool _saving = false;
  List<Map<String, String>> _searchResults = [];
  bool _showSearchResults = false;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: _start ?? now,
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final base = _start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: base,
      lastDate: DateTime(base.year + 5),
      initialDate: _end ?? base,
    );
    if (picked != null) setState(() => _end = picked);
  }

  void _searchUsers() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _searchResults = StorageService().searchUsers(query);
      _showSearchResults = true;
    });
  }

  void _selectUser(Map<String, String> user) {
    setState(() {
      _participants.text = _participants.text.isEmpty 
          ? user['userId']! 
          : '${_participants.text}, ${user['userId']!}';
      _searchController.clear();
      _showSearchResults = false;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _start == null || _end == null) return;
    setState(() => _saving = true);
    final ids = _participants.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await StorageService().createTrip(
      title: title,
      startDate: _start!,
      endDate: _end!,
      participantUserIds: ids,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final me = StorageService().currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16, // Fix overlap
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
                      'Trip Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Trip title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickStart,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(_start == null
                                ? 'Start date'
                                : _start!.toLocal().toString().split(' ').first),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickEnd,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                                _end == null ? 'End date' : _end!.toLocal().toString().split(' ').first),
                          ),
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
                      'Add Participants',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your User ID',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            me.userId,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this ID with others to add them to your trip',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _searchUsers(),
                      decoration: InputDecoration(
                        labelText: 'Search users by name or email',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchUsers();
                                },
                              )
                            : null,
                      ),
                    ),
                    if (_showSearchResults) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _searchResults.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No users found'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: Text(
                                        user['displayName']![0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user['displayName']!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      user['email']!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(Icons.add, size: 16),
                                    onTap: () => _selectUser(user),
                                  );
                                },
                              ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _participants,
                      decoration: const InputDecoration(
                        labelText: 'Selected participants (User IDs)',
                        helperText: 'User IDs will be added automatically when you search and select users',
                        prefixIcon: Icon(Icons.group_add),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      readOnly: true,
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
                label: const Text('Create Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


