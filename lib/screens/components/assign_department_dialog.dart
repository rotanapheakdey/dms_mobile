import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AssignDepartmentDialog extends StatefulWidget {
  const AssignDepartmentDialog({super.key});

  @override
  State<AssignDepartmentDialog> createState() => _AssignDepartmentDialogState();
}

class _AssignDepartmentDialogState extends State<AssignDepartmentDialog> {
  int? _selectedDeptId;
  final _noteController = TextEditingController();
  
  List<dynamic> _departments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBackendDepartments();
  }

  // Hits Route::get('/departments') from your api.php
  Future<void> _fetchBackendDepartments() async {
    final result = await ApiService.call('GET', '/departments');
    
    if (!mounted) return;

    if (result.containsKey('error') && result['error'] == true) {
      setState(() {
        _error = result['message'] ?? 'Failed to load departments';
        _isLoading = false;
      });
    } else {
      // Safely handles both raw arrays and object-wrapped data from Laravel
      final rawData = result['data'] ?? result['departments'] ?? result;
      setState(() {
        _departments = rawData is List ? rawData : [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text('Server Error'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      );
    }

    return AlertDialog(
      title: const Text('Select Destination Department'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The Dropdown choice element requested
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Choose Department',
                border: OutlineInputBorder(),
              ),
              value: _selectedDeptId,
              items: _departments.map((dept) {
                return DropdownMenuItem<int>(
                  value: dept['id'] as int,
                  child: Text(dept['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDeptId = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'DG Assignment Note (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // Stays disabled until the DG explicitly picks a department from the list
          onPressed: _selectedDeptId == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'assigned_department_id': _selectedDeptId,
                    'dg_note': _noteController.text.trim(),
                  });
                },
          child: const Text('Confirm Assignment'),
        ),
      ],
    );
  }
}