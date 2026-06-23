import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/document_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'layouts/main_layout.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/documents/document_detail_screen.dart';
import 'screens/documents/document_list_screen.dart';
import 'screens/documents/document_upload_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'utils/navigation_service.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const DMSApp(),
    ),
  );
}

class DMSApp extends StatelessWidget {
  const DMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'DMS',
          navigatorKey: NavigationService.navigatorKey,
          theme: themeProvider.currentTheme,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('km'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/main':
        return MaterialPageRoute(builder: (_) => const MainLayout());
      case '/documents':
        return MaterialPageRoute(builder: (_) => const DocumentListScreen());
      case '/document':
        final args = settings.arguments as Map<String, dynamic>?;
        final id = args?['id'] ?? 0;
        return MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(documentId: id),
        );
      case '/upload':
        return MaterialPageRoute(builder: (_) => const DocumentUploadScreen());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationScreen());
      case '/edit-profile':
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          fullscreenDialog: true,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}