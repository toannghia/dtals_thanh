import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../router/app_router.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  FirebaseMessaging? _fcm;
  bool _isInitialized = false;

  NotificationService(this._ref) {
    if (Firebase.apps.isNotEmpty) {
      _fcm = FirebaseMessaging.instance;
    }
  }

  Future<void> initialize() async {
    if (_fcm == null || _isInitialized) return;
    _isInitialized = true;

    // 1. Request Permission
    NotificationSettings settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
      
      // 2. Get Token
      String? token = await _fcm!.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      // 3. Listen for token refresh
      _fcm!.onTokenRefresh.listen((newToken) {
        _registerToken(newToken);
      });

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Foreground message: ${message.notification?.title}');
        }
        // You can use flutter_local_notifications here to show a peek
      });

      // 5. Handle Interaction (Background/Quit state)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);

      // 6. Check if app was opened from a terminated state via a notification
      RemoteMessage? initialMessage = await _fcm!.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageClick(initialMessage);
      }
    }
  }

  void _handleMessageClick(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification clicked: ${message.data}');
    }
    
    final type = message.data['type']?.toString().toUpperCase();
    final id = message.data['id']?.toString() ?? message.data['ticketId']?.toString();
    
    final router = _ref.read(routerProvider);
    
    switch (type) {
      case 'ORDER_STATUS':
        router.push('/user/orders');
        break;
      case 'SUPPORT_REPLY':
      case 'TICKET_STATUS':
        if (id != null) {
          router.push('/user/support/$id');
        } else {
          router.push('/user/support');
        }
        break;
      case 'EKYC_STATUS':
        router.push('/user/profile');
        break;
      default:
        router.push('/notifications');
        break;
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      String platform;
      if (kIsWeb) {
        platform = 'web';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        platform = 'android';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      } else {
        platform = 'unknown';
      }
      
      await _ref.read(notificationRepositoryProvider).registerDeviceToken(token, platform);
      if (kDebugMode) {
        print('FCM Token registered: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token: $e');
      }
    }
  }
}
