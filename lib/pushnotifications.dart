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

// void showIncomingCall() async {
//   CallKitParams params = const CallKitParams(
//     id: 'unique_id',
//     nameCaller: 'Caller Name',
//     appName: 'Your App Name',
//     avatar: 'https://example.com/avatar.png',
//     handle: '0123456789',
//     type: 0, // 0: audio, 1: video
//     duration: 30000,
//     textAccept: 'Accept',
//     textDecline: 'Decline',
//     // missedCallNotification: NotificationParams(0, true, 'Test', 'Test', true),
//     extra: <String, dynamic>{'userId': 'user_id'},
//     headers: <String, dynamic>{'apiKey': 'api_key'},
//     android: AndroidParams(
//       isCustomNotification: true,
//       isShowLogo: false,
//       // isShowCallback: true,
//       ringtonePath: 'system_ringtone_default',
//       backgroundColor: '#0955fa',
//       // background: 'https://example.com/background.png',
//       actionColor: '#4CAF50'
//     ),
//   );
//   await FlutterCallkitIncoming.showCallkitIncoming(params);
// }

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
          .where('phone_number', isEqualTo: int.parse(phone_number))
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
            'body': {'content':body, 'uid': FirebaseAuth.instance.currentUser?.uid},
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
      // final context = globalKey.currentContext;
      // if (context != null) {
      //   showDialog(context: context, builder: (_) => const EmergencyDialog());
      // } else {
      //   runApp(const EmergencyDialog());
      // }
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
