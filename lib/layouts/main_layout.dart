import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/documents/document_list_screen.dart';
import '../screens/archive/archive_search_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/widget/common/bottom_nav.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // 4 tabs: 0=Home/Dashboard, 1=Documents, 2=Archive, 3=Profile
  final List<Widget> _screens = [
    const DashboardScreen(),
    const DocumentListScreen(),
    const ArchiveSearchScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onUploadTap() {
    Navigator.pushNamed(context, '/upload');
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      // No AppBar — each screen has its own
      extendBody: true, // content flows behind the floating nav
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        notificationCount: notifProvider.unreadCount,
        onUploadTap: _onUploadTap,
      ),
    );
  }
}
