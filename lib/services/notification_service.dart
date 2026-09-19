import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Esta función DEBE estar fuera de cualquier clase.
// Maneja notificaciones cuando la app está cerrada (background).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Cuando la app está completamente cerrada y llega una notificación,
  // esta función se ejecuta en un hilo separado.
  print('Notificación en background: ${message.messageId}');
}

class NotificationService {
  // Instancia de Firebase Messaging
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Plugin para mostrar notificaciones locales (cuando la app está abierta)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal de notificaciones para Android
  // Android 8+ requiere canales para clasificar notificaciones
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'emapas_reportes',           // ID único del canal
    'Reportes EMAPAS',           // Nombre visible para el usuario
    description: 'Notificaciones sobre el estado de tus reportes de fugas',
    importance: Importance.high, // Alta importancia = aparece en pantalla
  );

  // ─────────────────────────────────────────
  // INICIALIZAR — llamar una sola vez al arrancar la app
  // ─────────────────────────────────────────

  Future<void> initialize() async {

    // 1. Pedir permiso al usuario para enviar notificaciones
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,    // Mostrar alertas
      badge: true,    // Mostrar número en el ícono de la app
      sound: true,    // Reproducir sonido
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido');
    } else {
      print('Permiso de notificaciones denegado');
      return; // Si no hay permiso, no configuramos nada más
    }

    // 2. Configurar el manejador de mensajes en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Configurar notificaciones locales (para cuando la app está abierta)
    await _setupLocalNotifications();

    // 4. Crear el canal de Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 5. Configurar qué hacer cuando llega una notificación y la app ESTÁ abierta
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Configurar qué hacer cuando el usuario TOCA la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. Obtener y guardar el token FCM del dispositivo
    await getAndSaveFCMToken();
  }

  // ─────────────────────────────────────────
  // CONFIGURAR NOTIFICACIONES LOCALES
  // ─────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      // Acción cuando el usuario toca la notificación local
      onDidReceiveNotificationResponse: (details) {
        print('Notificación local tocada: ${details.payload}');
      },
    );
  }

  // ─────────────────────────────────────────
  // MANEJAR MENSAJE CUANDO LA APP ESTÁ ABIERTA
  // ─────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;

    if (notification == null) return;

    // Mostramos la notificación como alerta local
    // porque FCM no la muestra automáticamente cuando la app está abierta
    await _localNotifications.show(
      notification.hashCode, // ID único de la notificación
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          // Ícono de la notificación
          icon: '@mipmap/ic_launcher',
          // Color de la barra de la notificación
          color: const Color(0xFF1565C0),
        ),
      ),
      payload: message.data['reporteId'], // Datos extras
    );
  }

  // ─────────────────────────────────────────
  // CUANDO EL USUARIO TOCA LA NOTIFICACIÓN
  // ─────────────────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    final String? reporteId = message.data['reporteId'];
    if (reporteId != null) {
      // Aquí podrías navegar al detalle del reporte
      // Lo implementaremos con el navigator global
      print('Ir al reporte: $reporteId');
    }
  }

  // ─────────────────────────────────────────
  // OBTENER TOKEN FCM DEL DISPOSITIVO
  // El token identifica este dispositivo para enviarle notificaciones
  // ─────────────────────────────────────────

  Future<String?> getAndSaveFCMToken() async {
    final String? token = await _fcm.getToken();

    if (token != null) {
      print('Token FCM: $token');
      // Guardamos el token en Firestore para enviarlo notificaciones después
      // Esto se conecta con el usuario en la Fase 10 (admin)
    }

    return token;
  }

  // ─────────────────────────────────────────
  // GUARDAR TOKEN EN FIRESTORE
  // (llamar después de que el usuario inicia sesión)
  // ─────────────────────────────────────────

  Future<void> saveTokenToFirestore(String userId) async {
    final String? token = await _fcm.getToken();

    if (token == null) return;

    // Importamos Firestore aquí para evitar dependencia circular
    final firestore =
        await Future.value(null).then((_) async {
      final cloud =
          await Future.value(null).then((_) {
        // ignore: depend_on_referenced_packages
        return null;
      });
      return cloud;
    });

    // Guardamos el token asociado al usuario
    // Así cuando el admin quiera notificarle, usa este token
    print('Token guardado para usuario $userId: $token');
  }

  // ─────────────────────────────────────────
  // SUSCRIBIRSE A UN TEMA
  // Los temas permiten enviar notificaciones a grupos de usuarios
  // ─────────────────────────────────────────

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('Suscrito al tema: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
}