import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/map_cache_stub_native.dart'
    if (dart.library.html) 'core/services/map_cache_stub_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initWebViewPlatform();

  // Enable edge-to-edge and transparent system bars for Android 15+ behavior.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  
  try {
    await initMapCaching();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Initialization failed: $e');
  }

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          // Initialize push notifications
          ref.read(notificationServiceProvider).initialize();
          return const MyApp();
        },
      ),
    ),
  );
}

void _initWebViewPlatform() {
  if (kIsWeb) return;
  if (WebViewPlatform.instance != null) return;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      WebViewPlatform.instance = AndroidWebViewPlatform();
      break;
    case TargetPlatform.iOS:
      WebViewPlatform.instance = WebKitWebViewPlatform();
      break;
    default:
      break;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'DTALS Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
