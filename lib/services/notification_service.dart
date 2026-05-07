import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:time_zone_plus/time_zone_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // DETECTAR ZONA HORARIA LOCAL USANDO time_zone_plus con fallback a UTC
    final String timeZoneName = await TimeZonePlus.getCurrentTimeZone() ?? 'UTC';
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Notificación presionada: ${details.payload}");
      },
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final hasNotificationPermission = await androidPlugin.requestNotificationsPermission();
      final bool? canScheduleExact = await androidPlugin.canScheduleExactNotifications();
      
      print("--- DIAGNÓSTICO DE INICIO ---");
      print("1. Permiso de Notificación: $hasNotificationPermission");
      print("2. ¿Puede programar alarmas exactas?: $canScheduleExact");
      print("3. Reloj de la App: ${tz.TZDateTime.now(tz.local)}");
    }
  }

  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_priority_channel_v5', // Nuevo canal
        'Alertas Críticas',
        importance: Importance.max,
        priority: Priority.max, // Máxima prioridad
        channelShowBadge: true,
        fullScreenIntent: true,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // --- MÉTODOS DE PRODUCCIÓN ---

  Future<void> scheduleIntervalNotification({required int hours}) async {
    await _notificationsPlugin.periodicallyShow(
      0,
      '¡Recordatorio!',
      'Es hora de alimentar a tu mascota (cada $hours horas)',
      RepeatInterval.values.firstWhere((e) => e.index == (hours == 1 ? 2 : 3)),
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleFixedTimeNotification({required int hour, required int minute}) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);
    print("Programando notificación DIARIA para: $scheduledDate");

    await _notificationsPlugin.zonedSchedule(
      1,
      '¡Atención!',
      'Es hora de alimentar a tu mascota',
      scheduledDate,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleOneTimeNotification({required int minutes}) async {
    // COMPARACIÓN DE RELOJES
    final systemNow = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);

    print("--- COMPROBACIÓN DE RELOJES ---");
    print("Reloj Sistema (Android): $systemNow");
    print("Reloj TZ (Librería): $tzNow");
    print("Diferencia detectada: ${systemNow.difference(tzNow).inSeconds} segundos");

    final scheduledTime = tzNow.add(Duration(minutes: minutes));

    print("Programando para: $scheduledTime");

    await _notificationsPlugin.zonedSchedule(
      DateTime.now().millisecond, // ID único basado en milisegundos
      '¡Alarma de Mascota!',
      'Han pasado $minutes minutos.',
      scheduledTime,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    print("Registrada con éxito.");
  }
  // --- MÉTODOS DE DIAGNÓSTICO ---

  Future<void> showImmediateNotification() async {
    print("--- PRUEBA INSTANTÁNEA ---");
    await _notificationsPlugin.show(
      99,
      '¡Prueba OK!',
      'El motor de notificaciones está vivo.',
      _getNotificationDetails(),
    );
  }

  Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pendingRequests = await _notificationsPlugin.pendingNotificationRequests();
    print("--- PENDIENTES EN EL SISTEMA ---");
    print("Total: ${pendingRequests.length}");
    for (var r in pendingRequests) {
      print("- [ID ${r.id}] ${r.title}");
    }
  }

/*  Future<void> testInexactScheduling() async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 15));
    await _notificationsPlugin.zonedSchedule(
      88,
      'Prueba Inexacta',
      'Lanzada a los 15 segundos.',
      scheduledTime,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    print("Inexacta registrada para: $scheduledTime");
  }*/

  Future<void> openAlarmSettings() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) await androidPlugin.requestExactAlarmsPermission();
  }

  // --- LÓGICA DE TIEMPO ---

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);  // hora y minuto que yo estoy definiendo
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1)); // le sumamos un día para decir "si la alarma ya sonó, que suene a la misma hora mañana"
    }
    return scheduledDate;
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    print("Limpieza completa.");
  }
}