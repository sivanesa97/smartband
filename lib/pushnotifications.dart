import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:volume_controller/volume_controller.dart';

import 'main.dart';

class SendNotification {
  Future<String> getAccessToken() async {
    final jsonString =
        await rootBundle.loadString('assets/service_account.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(jsonString);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(serviceAccount, scopes);
    final accessToken = client.credentials.accessToken;
    return accessToken.data;
  }

  Future<void> sendNotification(
      String phone_number, String title, String body) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print(phone_number);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      final data = await FirebaseFirestore.instance
          .collection("users")
          .where('phone_number', isEqualTo: phone_number)
          .get();
      // print(data.docs.first.data());
      final targetToken = data.docs.first.data()['fcmKey'];
      final token = await getAccessToken();
      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/smartband-keydraft/messages:send');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final payload = json.encode({
        'message': {
          'token': targetToken,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      });

      final response = await http.post(url, headers: headers, body: payload);

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> showNotification(
      String title, String msg, GlobalKey<NavigatorState> globalKey) async {
    VolumeController().setVolume(1, showSystemUI: false);
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails("default_channel_id", 'channel.name',
            channelDescription: 'description',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('ringtone'),
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.call,
            visibility: NotificationVisibility.public,
            timeoutAfter: 60000,
            color: Colors.red);

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    if (title == "Emergency!!") {
      // showIncomingCall();
      print("Inside Emergency");

      final context = globalKey.currentContext;
      if (context != null) {
        globalKey.currentState?.pushNamed('/sos');
        //   showDialog(context: context, builder: (_) => const EmergencyDialog());
        // } else {
        //   runApp(const EmergencyDialog());
      }
    } else {
      globalKey.currentState?.pushNamed('/sos');
    }
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      msg,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}
