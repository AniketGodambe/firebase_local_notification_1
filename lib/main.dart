import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  importance: Importance.max,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  await GetStorage.init('type');

  //for in app notifications
  if (Platform.isAndroid) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(getMessages);
    FirebaseMessaging.onMessage.listen(getMessages);
  } else {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedAppFnIos);
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  // ignore: unused_local_variable
  final List<ActiveNotification>? activeNotifications =
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: false, sound: true);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_logo');

  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
    defaultPresentAlert: true,
    defaultPresentSound: true,
    notificationCategories: [
      DarwinNotificationCategory(
        'category',
        options: {
          DarwinNotificationCategoryOption.allowAnnouncement,
        },
        actions: [
          DarwinNotificationAction.plain(
            'snoozeAction',
            'snooze',
          ),
          DarwinNotificationAction.plain(
            'confirmAction',
            'confirm',
            options: {
              DarwinNotificationActionOption.authenticationRequired,
            },
          ),
        ],
      ),
    ],
  );
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveBackgroundNotificationResponse: notificationData,
    onDidReceiveNotificationResponse: (NotificationResponse value) {
      // commonControllert.notificatinNavigations(value.payload.toString());
    },
  );

  await GetStorage.init();
  flutterLocalNotificationsPlugin
      .getNotificationAppLaunchDetails()
      .then((value) {
    if (value!.didNotificationLaunchApp) {
      if (value.notificationResponse!.payload != null) {
        GetStorage('type')
            .write('type', value.notificationResponse!.payload.toString());
      }
    }
  });
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });
}

void onMessageOpenedAppFnIos(RemoteMessage message) {
  log("onMessageOpenedAppFn");
  //add your navigations here
  //Get.to(()=> Pagename());
}

void getMessages(RemoteMessage message) {
  triggerNotification(message);
}

@pragma('vm:entry-point')
notificationData(NotificationResponse value) async {
  // commonControllert.notificatinNavigations(value.payload.toString());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  triggerNotification(message);
  await Firebase.initializeApp();
}

void triggerNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (android != null && notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['screen'].toString(),
    );
  } else {
    log("custom notification");
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      message.data['title'],
      message.data['body'],
      NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails()),
      payload: message.data['screen'].toString(),
    );
    return;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //for ios background notifications
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    GetStorage('type').write('type', message.data['type'] ?? "".toString());
  }

  @override
  void initState() {
    if (Platform.isIOS) {
      setupInteractedMessage();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Local Notifications',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Firebase Local Notifications"),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Just copy paste",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
