import 'package:flutter/material.dart';
import '../models/document.dart';
import '../services/api_service.dart';
import 'document_detail_screen.dart';

class ArchiveSearchScreen extends StatefulWidget {
  const ArchiveSearchScreen({super.key});

  @override
  State<ArchiveSearchScreen> createState() => _ArchiveSearchScreenState();
}

class _ArchiveSearchScreenState extends State<ArchiveSearchScreen> {
  final _searchController = TextEditingController();
  List<Document> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _accessLevel = "Loading...";

  @override
  void initState() {
    super.initState();
    // AUTOMATIC LOAD: Fetch all available archives immediately on screen initialization
    _executeSearch("");
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Hits your route through the 10.0.2.2 virtual routing gateway
    final result = await ApiService.call('GET', '/documents/archive?search=$query');

    if (!mounted) return;

    if (result.containsKey('error') && result['error'] == true) {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
    } else {
      final List<dynamic> docData = result['documents'] ?? [];
      setState(() {
        _searchResults = docData.map((json) => Document.fromJson(json)).toList();
        _accessLevel = result['access_level'] ?? 'Global'; //
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Archived Scope: $_accessLevel', 
            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search archive by title or control no...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _executeSearch(""); // Reset search to show all archives on clear
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              _executeSearch(value.trim());
            },
          ),
        ),

        // Results Feed Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : _searchResults.isEmpty
                      ? const Center(child: Text('No archived documents found.'))
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = _searchResults[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.archive_outlined, color: Colors.white),
                              ),
                              title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${doc.controlNo}\nDept: ${doc.department?['name'] ?? "Global"}'),
                              trailing: const Icon(Icons.chevron_right),
                              isThreeLine: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DocumentDetailScreen(document: doc),
                                  ),
                                );
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}