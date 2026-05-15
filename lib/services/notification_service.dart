import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:time_zone_plus/time_zone_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _paseoReminderBaseId = 1000;
  static const int _paseoReminderMaxCount = 24;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // DETECTAR ZONA HORARIA LOCAL USANDO time_zone_plus con fallback a UTC
    final String timeZoneName = TimeZonePlus.getCurrentTimeZone() ?? 'UTC';
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notificación presionada: ${details.payload}");
      },
    );
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
    if (hours == 1) {
      await _notificationsPlugin.periodicallyShow(
        0,
        '¡Recordatorio!',
        'Es hora de alimentar a tu mascota cada hora.',
        RepeatInterval.hourly,
        _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return;
    }

    if (hours == 24) {
      await _notificationsPlugin.periodicallyShow(
        0,
        '¡Recordatorio!',
        'Es hora de alimentar a tu mascota.',
        RepeatInterval.daily,
        _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return;
    }

    final scheduledDate = DateTime.now().add(Duration(hours: hours));
    await scheduleOneTimeNotification(
      id: 0,
      scheduledFor: scheduledDate,
      title: '¡Recordatorio!',
      body: 'Es hora de alimentar a tu mascota.',
    );
  }

  Future<void> schedulePaseoReminders({
    required int objetivo,
    required int completadosHoy,
    required int intervaloHoras,
    required String mascotaNombre,
  }) async {
    await cancelPaseoReminders();

    if (completadosHoy >= objetivo) return;

    final now = DateTime.now();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    DateTime nextReminder = now.add(Duration(hours: intervaloHoras));

    for (
      var index = 0;
      nextReminder.isBefore(endOfDay) && index < _paseoReminderMaxCount;
      index++, nextReminder = nextReminder.add(Duration(hours: intervaloHoras))
    ) {
      await scheduleOneTimeNotification(
        id: _paseoReminderBaseId + index,
        scheduledFor: nextReminder,
        title: 'Recordatorio de paseo',
        body: '¡No olvides sacar a pasear a $mascotaNombre hoy!',
      );
    }
  }

  Future<void> cancelPaseoReminders() async {
    for (
      var id = _paseoReminderBaseId;
      id < _paseoReminderBaseId + _paseoReminderMaxCount;
      id++
    ) {
      await cancel(id);
    }
  }

  Future<void> scheduleFixedTimeNotification({
    required int id,
    required int hour,
    required int minute,
    required String mascotaNombre,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notificationsPlugin.zonedSchedule(
      id,
      '¡Hora de comer!',
      'Es hora de alimentar a $mascotaNombre',
      scheduledDate,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleOneTimeNotification({
    required int id,
    required DateTime scheduledFor,
    required String title,
    required String body,
  }) async {
    final scheduledTime = tz.TZDateTime.from(scheduledFor, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  // --- MÉTODOS DE DIAGNÓSTICO ---

  Future<void> showImmediateNotification() async {
    debugPrint("--- PRUEBA INSTANTÁNEA ---");
    await _notificationsPlugin.show(
      99,
      '¡Prueba OK!',
      'El motor de notificaciones está vivo.',
      _getNotificationDetails(),
    );
  }

  Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pendingRequests =
        await _notificationsPlugin.pendingNotificationRequests();
    debugPrint("--- PENDIENTES EN EL SISTEMA ---");
    debugPrint("Total: ${pendingRequests.length}");
    for (var r in pendingRequests) {
      debugPrint("- [ID ${r.id}] ${r.title}");
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _notificationsPlugin.pendingNotificationRequests();

  Future<bool> hasPendingPaseoReminders() async {
    final pending = await getPendingNotifications();
    return pending.any(
      (n) => n.id >= _paseoReminderBaseId && n.id < _paseoReminderBaseId + _paseoReminderMaxCount,
    );
  }

  Future<bool> hasExactAlarmPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return true; // iOS no lo necesita
    return (await androidPlugin.canScheduleExactNotifications()) ?? false;
  }

  Future<bool> hasNotificationPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return true;
    return (await androidPlugin.requestNotificationsPermission()) ?? false;
  }

  Future<void> openAlarmSettings() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  // --- LÓGICA DE TIEMPO ---

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ); // hora y minuto que yo estoy definiendo
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: 1),
      ); // le sumamos un día para decir "si la alarma ya sonó, que suene a la misma hora mañana"
    }
    return scheduledDate;
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint("Notificación cancelada: ID $id");
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("Limpieza completa.");
  }
}
