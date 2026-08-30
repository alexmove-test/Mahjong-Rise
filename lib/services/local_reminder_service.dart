import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n.dart';
import '../models/pet.dart';
import '../models/week_id.dart';
import 'analytics_service.dart';
import 'pet_store.dart';
import 'progress_store.dart';
import 'reminder_store.dart';

/// Локальные слоты: daily 19:00, streak 20:00, понедельник 10:00.
abstract final class LocalReminderService {
  LocalReminderService._();

  static const _dailyId = 1001;
  static const _streakId = 1002;
  static const _weekId = 1003;
  static const _petHungerAskId = 2001;
  static const _petPlayAskId = 2002;
  static const _petRestAskId = 2003;
  static const _petStarveId = 2004;
  static const _channelId = 'courtyard_reminders';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (response) {
          unawaitedLog(response.payload);
        },
      );

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        unawaitedLog(launch!.notificationResponse?.payload);
      }

      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static void unawaitedLog(String? payload) {
    AnalyticsService.log('notification_open', {
      if (payload != null && payload.isNotEmpty) 'kind': payload,
    });
  }

  static Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> resync({required L10n l10n}) async {
    await init();
    final reminder = await ReminderStore.open();
    if (!reminder.enabled) {
      await cancelAll();
      return;
    }
    final progress = await ProgressStore.open();
    await progress.ensureWeek();
    await progress.expireStreakIfNeeded();
    await schedule(
      l10n: l10n,
      streak: progress.visibleStreak(),
      dailyDoneToday: progress.isDailyCompletedOn(DateTime.now()),
    );
    final pets = await PetStore.open();
    await schedulePets(l10n: l10n, pets: pets);
  }

  static Future<void> schedule({
    required L10n l10n,
    required int streak,
    required bool dailyDoneToday,
  }) async {
    await init();
    if (!_ready) return;
    final reminder = await ReminderStore.open();
    if (!reminder.enabled) {
      await cancelAll();
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminders,
        channelDescription: l10n.reminders,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _plugin.cancel(id: _dailyId);
      await _plugin.cancel(id: _streakId);
      await _plugin.cancel(id: _weekId);

      final dailyWhen = dailyDoneToday
          ? _nextHour(19, skipToday: true)
          : _nextHour(19);
      await _plugin.zonedSchedule(
        id: _dailyId,
        scheduledDate: dailyWhen,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: l10n.reminderDailyTitle,
        body: l10n.reminderDailyBody,
        payload: 'daily',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (streak > 0 && !dailyDoneToday) {
        await _plugin.zonedSchedule(
          id: _streakId,
          scheduledDate: _nextHour(20),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: l10n.reminderStreakTitle,
          body: l10n.reminderStreakBody,
          payload: 'streak',
        );
      }

      await _plugin.zonedSchedule(
        id: _weekId,
        scheduledDate: _nextMondayTen(),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: l10n.reminderWeekTitle,
        body: l10n.reminderWeekBody,
        payload: 'week',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  static Future<void> schedulePets({
    required L10n l10n,
    required PetStore pets,
    DateTime? now,
  }) async {
    await init();
    if (!_ready) return;
    final reminder = await ReminderStore.open();
    if (!reminder.enabled) {
      await _cancelPetSlots();
      return;
    }
    if (!pets.hasPet) {
      await _cancelPetSlots();
      return;
    }

    final at = now ?? DateTime.now();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.reminders,
        channelDescription: l10n.reminders,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _cancelPetSlots();
      final hunger = pets.soonestClock(PetNeed.hunger);
      final play = pets.soonestClock(PetNeed.play);
      final rest = pets.soonestClock(PetNeed.rest);
      if (hunger != null) {
        final name = l10n.petName(hunger.kind);
        await _slotIfDue(
          id: _petHungerAskId,
          last: hunger.last,
          need: PetNeed.hunger,
          threshold: PetNeeds.askThreshold,
          now: at,
          details: details,
          title: l10n.reminderPetHungerTitle(name),
          body: l10n.reminderPetHungerBody,
          payload: 'pet:hunger',
        );
        await _slotIfDue(
          id: _petStarveId,
          last: hunger.last,
          need: PetNeed.hunger,
          threshold: 0,
          now: at,
          details: details,
          title: l10n.reminderPetStarveTitle(name),
          body: l10n.reminderPetStarveBody,
          payload: 'pet:starve',
        );
      }
      if (play != null) {
        final name = l10n.petName(play.kind);
        await _slotIfDue(
          id: _petPlayAskId,
          last: play.last,
          need: PetNeed.play,
          threshold: PetNeeds.askThreshold,
          now: at,
          details: details,
          title: l10n.reminderPetPlayTitle(name),
          body: l10n.reminderPetPlayBody,
          payload: 'pet:play',
        );
      }
      if (rest != null) {
        final name = l10n.petName(rest.kind);
        await _slotIfDue(
          id: _petRestAskId,
          last: rest.last,
          need: PetNeed.rest,
          threshold: PetNeeds.askThreshold,
          now: at,
          details: details,
          title: l10n.reminderPetRestTitle(name),
          body: l10n.reminderPetRestBody,
          payload: 'pet:rest',
        );
      }
    } catch (_) {}
  }

  static Future<void> _slotIfDue({
    required int id,
    required DateTime? last,
    required PetNeed need,
    required double threshold,
    required DateTime now,
    required NotificationDetails details,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (last == null) return;
    final when = PetNeeds.nextThreshold(
      lastSatisfied: last,
      need: need,
      threshold: threshold,
      now: now,
    );
    if (when == null) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  static Future<void> _cancelPetSlots() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _petHungerAskId);
      await _plugin.cancel(id: _petPlayAskId);
      await _plugin.cancel(id: _petRestAskId);
      await _plugin.cancel(id: _petStarveId);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static tz.TZDateTime _nextHour(int hour, {bool skipToday = false}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    if (skipToday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextMondayTen() {
    final monday = WeekId.fromDate(DateTime.now()).nextMonday;
    return tz.TZDateTime(tz.local, monday.year, monday.month, monday.day, 10);
  }
}
