import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  importance: Importance.max,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessageOpenedApp.listen(getMessages);
  FirebaseMessaging.onMessage.listen(getMessages);

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
    onDidReceiveNotificationResponse: (NotificationResponse value) {
      // commonControllert.notificatinNavigations(value.payload.toString());
    },
  );

  runApp(const MyApp());
}

void getMessages(RemoteMessage message) {
  triggerNotification(message);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  triggerNotification(message);
  await Firebase.initializeApp();
  log('A bg message just showed up :  ${message.messageId}');
  log('Got a message whilst in the Background!');
  log('Message data:: ${message.data}');
  log('Message category:: ${message.category}');
  log('Message collapseKey:: ${message.collapseKey}');
  log('Message contentAvailable:: ${message.contentAvailable}');
  log('Message from:: ${message.from}');
  log('Message messageType:: ${message.messageType}');
  log('Message mutableContent:: ${message.mutableContent}');
}

void triggerNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (android != null && notification != null) {
    log('android:: ${notification.android}');
    log('apple:: ${notification.apple}');
    log('body:: ${notification.body}');
    log('bodyLocArgs:: ${notification.bodyLocArgs}');
    log('bodyLocKey:: ${notification.bodyLocKey}');
    log('title:: ${notification.title}');
    log('titleLocArgs:: ${notification.titleLocArgs}');
    log('titleLocKey:: ${notification.titleLocKey}');
    log("firebase notification");

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demojhjhj hjhk ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Hello"),
        ),
        body: Column(children: const [
          Text("Hello"),
        ]),
      ),
    );
  }
}
