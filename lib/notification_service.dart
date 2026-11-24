import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:login_firebase/firebase_options.dart';
import 'package:login_firebase/screens/notification_detail_screen.dart';

/// Kunci global Navigator, supaya kita bisa pindah halaman
/// dari luar widget (misalnya saat notifikasi di-klik).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// HANDLER BACKGROUND / TERMINATED
/// - Wajib fungsi top-level (di luar class).
/// - Wajib diberi @pragma('vm:entry-point') agar tidak dibuang saat build release.
/// - Dipanggil saat pesan masuk ketika aplikasi di background / mati.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Pesan BACKGROUND: ${message.messageId}');
  debugPrint('[FCM] Data: ${message.data}');
  // Catatan: notifikasi di system tray sudah ditampilkan otomatis oleh
  // Android jika payload memiliki bagian "notification".
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Channel Android (Android 8+ wajib punya channel).
  /// ID ini HARUS sama dengan yang ada di AndroidManifest.xml
  /// dan di payload Postman ("channel_id").
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notifikasi Penting', // nama yang terlihat di pengaturan HP
    description: 'Channel untuk notifikasi dari Firebase Cloud Messaging',
    importance: Importance.max,
  );

  static Future<void> init() async {
    // 1. Minta izin notifikasi (Android 13+ akan muncul dialog izin)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Status izin: ${settings.authorizationStatus}');

    // 2. Inisialisasi flutter_local_notifications + buat channel
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidInit),
      // Dipanggil saat notifikasi LOKAL (foreground) di-klik
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _openDetail(jsonDecode(response.payload!) as Map<String, dynamic>);
        }
      },
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // 3. Ambil FCM Token (alamat tujuan notifikasi untuk device ini)
    try {
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      debugPrint('[FCM] TOKEN: $token');
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token: $e');
    }
    // ignore: deprecated_member_use
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] TOKEN BARU: $newToken');
    });

    // 4. Subscribe ke topic "kelas" (untuk kirim ke banyak device sekaligus)
    await _messaging.subscribeToTopic('kelas');

    // 5. FOREGROUND: pesan masuk saat aplikasi sedang dibuka
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // 6. BACKGROUND -> klik notifikasi -> aplikasi kembali terbuka
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Dibuka dari BACKGROUND');
      _openDetail(_messageToMap(message));
    });

    // 7. TERMINATED -> klik notifikasi -> aplikasi dijalankan dari awal
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] Dibuka dari kondisi MATI (terminated)');
      _openDetail(_messageToMap(initialMessage));
    }

    // 8. (Tambahan) Aplikasi dibuka dari notifikasi LOKAL saat app sudah mati
    final launchDetails = await _localNotif.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if ((launchDetails?.didNotificationLaunchApp ?? false) && payload != null) {
      _openDetail(jsonDecode(payload) as Map<String, dynamic>);
    }
  }

  /// Menampilkan notifikasi saat aplikasi di FOREGROUND.
  /// Android TIDAK menampilkan notifikasi FCM secara otomatis
  /// jika aplikasi sedang dibuka, jadi kita tampilkan sendiri.
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    debugPrint('[FCM] Pesan FOREGROUND: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(_messageToMap(message)),
    );
  }

  /// Gabungkan title, body, dan data menjadi satu Map.
  static Map<String, dynamic> _messageToMap(RemoteMessage message) {
    return {
      'title': message.notification?.title ?? '-',
      'body': message.notification?.body ?? '-',
      ...message.data,
    };
  }

  /// Buka halaman detail notifikasi.
  static void _openDetail(Map<String, dynamic> data) {
    void push() {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => NotificationDetailScreen(data: data),
        ),
      );
    }

    // Jika Navigator belum siap (aplikasi baru start), tunggu frame pertama.
    if (navigatorKey.currentState != null) {
      push();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => push());
    }
  }
}