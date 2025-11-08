import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class JoinTripScreen extends StatefulWidget {
  const JoinTripScreen({super.key});

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _joining = false;

  Future<void> _join() async {
    setState(() {
      _error = null;
      _joining = true;
    });
    try {
      await StorageService().joinTripByCode(_code.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Trip not found');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Join code'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _joining ? null : _join,
                child: _joining
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




