import 'package:dms_mobile/utils/dialog_helper.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'upload_screen.dart';
import '../providers/document_provider.dart';
import 'login_screen.dart';
import 'document_detail_screen.dart';
import 'archive_search_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentView = 'urgent';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchUrgentFeed();
    });
  }

  Widget _statusBadge(String status) {
    Map<String, Color> colors = {
      'pending_dg_init': const Color(0xFFEF5350),
      'pending_dispatch': const Color(0xFFFFA726),
      'dg_directed': const Color(0xFF42A5F5),
      'pending_vdg_approval': const Color(0xFFAB47BC),
      'pending_dg_approval': const Color(0xFFFFCA28),
      'dg_signed': const Color(0xFF66BB6A),
      'completed_archive': const Color(0xFFBDBDBD),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors[status] ?? Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final docState = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentView == 'urgent' ? 'Urgent Workspace' : 'Digital Archive',
        ),
        actions: [
          if (_currentView == 'urgent')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<DocumentProvider>().fetchUrgentFeed(),
            ),
        ],
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1976D2)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF1976D2)),
              ),
              accountName: Text(
                user?['name'] ?? 'User Name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user?['email'] ?? 'user@example.com'),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ROLE: ${(user?['role'] ?? 'Unknown').toString().toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.speed, color: Colors.red),
              title: const Text('Urgent Feed'),
              trailing: docState.urgentCount > 0
                  ? Badge(label: Text('${docState.urgentCount}'))
                  : null,
              selected: _currentView == 'urgent',
              onTap: () {
                setState(() => _currentView = 'urgent');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.blue),
              title: const Text('Archive Repository'),
              selected: _currentView == 'archive',
              onTap: () {
                setState(() => _currentView = 'archive');
                Navigator.pop(context);
              },
            ),

            const Divider(),
            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: const Text('Log Out'),
              onTap: () async {
                final confirm = await DialogHelper.showConfirmation(
                  context: context,
                  title: 'Log Out',
                  content:
                      'Are you sure you want to end your session and log out of the system?',
                  confirmLabel: 'Log Out',
                  confirmColor: Colors.red.shade700,
                  icon: Icons.logout,
                );

                if (confirm && context.mounted) {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      body: _currentView == 'urgent'
          ? Column(
              children: [
                Expanded(
                  child: docState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : docState.errorMessage != null
                      ? Center(
                          child: Text(
                            docState.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : docState.urgentDocuments.isEmpty
                      ? const Center(
                          child: Text('No urgent documents pending.'),
                        )
                      : ListView.separated(
                          itemCount: docState.urgentDocuments.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = docState.urgentDocuments[index];

                            // Custom theme colors derived from the document status rules
                            Color statusColor;
                            switch (doc.status) {
                              case 'pending_dg_init':
                                statusColor = const Color(0xFFE53935);
                                break; // Red
                              case 'pending_dispatch':
                                statusColor = const Color(0xFFFB8C00);
                                break; // Orange
                              case 'dg_directed':
                                statusColor = const Color(0xFF1E88E5);
                                break; // Blue
                              case 'pending_vdg_approval':
                                statusColor = const Color(0xFF8E24AA);
                                break; // Purple
                              case 'pending_dg_approval':
                                statusColor = const Color(0xFFFFB300);
                                break; // Amber
                              case 'dg_signed':
                                statusColor = const Color(0xFF43A047);
                                break; // Green
                              default:
                                statusColor = Colors.grey.shade600;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DocumentDetailScreen(document: doc),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Control Number Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              doc.controlNo,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Dynamic Status Chip
                                          _statusBadge(doc.status),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Document Title
                                      Text(
                                        doc.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),

                                      // Footer Details
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.business,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                doc.department?['name'] ??
                                                    'Unassigned',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                doc.createdAt.split('T')[0],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            )
          : const ArchiveSearchScreen(),

      floatingActionButton:
          user?['role'] == 'file_dept' && _currentView == 'urgent'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                );
              },
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }
}
