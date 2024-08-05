import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'main.dart';

class SendNotification {
  Future<String> getAccessToken() async {
    final jsonString = await rootBundle.loadString('assets/service_account.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(jsonString);

    final scopes = [ 'https://www.googleapis.com/auth/firebase.messaging' ];
    final client = await clientViaServiceAccount(serviceAccount, scopes);
    final accessToken = await client.credentials.accessToken;
    return accessToken.data;
  }

  Future<void> sendNotification(String phone_number, String title, String body) async {
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
      final data = await FirebaseFirestore.instance.collection("users").where('phone_number',isEqualTo: int.parse(phone_number)).get();
      print(data.docs.first.data());
      final targetToken = data.docs.first.data()['fcmKey'];
      final token = await getAccessToken();

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/smartband1-81618/messages:send');
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> showNotification(String title, String msg) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'Notification Id',
        'Android Notification',
        enableVibration: true,
        channelDescription: 'description',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('ringtone'),
        priority: Priority.high,
        playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      msg,
      platformChannelSpecifics,
      payload: 'item x',
    );

  }
}
