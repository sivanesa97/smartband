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
import 'package:geolocator/geolocator.dart';
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
    }
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      msg,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> sendAlarmNotification(
      String fcmToken, String title, String body) async {
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
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await getAccessToken();
      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/smartband-keydraft/messages:send');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final payload = json.encode({
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high', // Move priority here
            'notification': {
              'sound': 'default',
              'channel_id': 'alarm_channel',
            },
          },
        },
      });

      final response = await http.post(url, headers: headers, body: payload);

      if (response.statusCode == 200) {
        print('Alarm notification sent successfully');
      } else {
        print('Failed to send alarm notification: ${response.body}');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Future<void> checkLocationAndSendNotification() async {
  //   Position currentPosition = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );

  //   DocumentSnapshot userDoc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(FirebaseAuth.instance.currentUser!.uid)
  //       .get();
  //   Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
  //   GeoPoint homeLocation = userData['homeLocation'] as GeoPoint;

  //   double distance = Geolocator.distanceBetween(
  //     currentPosition.latitude,
  //     currentPosition.longitude,
  //     homeLocation.latitude,
  //     homeLocation.longitude,
  //   );

  //   if (distance > 10000) {
  //     setState(() {
  //       _isEmergency = true;
  //     });
  //     for (var attempt = 1; attempt <= 3; attempt++) {
  //       if (!_isEmergency) {
  //         break;
  //       }
  //       print("Attempt ");
  //       print(attempt);
  //       // Position location = await updateLocation();
  //       try {
  //         if (FirebaseAuth.instance.currentUser!.uid.isNotEmpty) {
  //           await FirebaseFirestore.instance
  //               .collection("users")
  //               .doc(FirebaseAuth.instance.currentUser!.uid)
  //               .update({
  //             "metrics": {
  //               "spo2": "168",
  //               "heart_rate": "200",
  //               "fall_axis": "-- -- --"
  //             }
  //           });
  //         }
  //         final data = await FirebaseFirestore.instance
  //             .collection("users")
  //             .where('phone_number', isEqualTo: '+94965538193')
  //             .get();
  //         SendNotification send = SendNotification();
  //         for (QueryDocumentSnapshot<Map<String, dynamic>> i in data.docs) {
  //           print(i);
  //           if (!_isEmergency) {
  //             break;
  //           }

  //           await FirebaseFirestore.instance
  //               .collection("emergency_alerts")
  //               .doc(i.id)
  //               .set({
  //             "isEmergency": true,
  //             "responseStatus": false,
  //             "response": "",
  //             "userUid": FirebaseAuth.instance.currentUser?.uid,
  //             "heartbeatRate": '93',
  //             "location": "0°N 0°E",
  //             "sfo2": '35',
  //             "fallDetection": false,
  //             "isManual": true,
  //             "timestamp": FieldValue.serverTimestamp()
  //           }, SetOptions(merge: true));

  //           await FirebaseFirestore.instance
  //               .collection("emergency_alerts")
  //               .doc(i.id)
  //               .collection(FirebaseAuth.instance.currentUser?.uid ?? "public")
  //               .add({
  //             "isEmergency": true,
  //             "responseStatus": false,
  //             "response": "",
  //             "heartbeatRate": '93',
  //             "location": "0°N 0°E",
  //             "sfo2": '35',
  //             "fallDetection": false,
  //             "isManual": true,
  //             "timestamp": FieldValue.serverTimestamp()
  //           });

  //           Map<String, String> supervisors =
  //               Map<String, String>.from(i.data()['supervisors']);
  //           var sortedSupervisors = supervisors.entries.toList()
  //             ..sort(
  //                 (a, b) => int.parse(b.value).compareTo(int.parse(a.value)));

  //           for (var supervisor in sortedSupervisors) {
  //             String message =
  //                 "${FirebaseAuth.instance.currentUser?.displayName} has moved more than 10 km from home. Current location is ${currentPosition.latitude}°N, ${currentPosition.longitude}°E. Please respond.";
  //             await send.sendNotification(
  //                 supervisor.key, "Emergency!!", message);
  //             await Future.delayed(Duration(seconds: 30));
  //             print(
  //                 "Message sent to supervisor with phone number: ${supervisor.key} and priority: ${supervisor.value}");
  //           }

  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text("Sent Alert to ${i.data()['name']}")),
  //           );
  //           FirebaseFirestore.instance
  //               .collection("emergency_alerts")
  //               .doc(i.id)
  //               .snapshots()
  //               .listen((DocumentSnapshot doc) {
  //             if (doc.exists && doc["responseStatus"] == true) {
  //               String responderName = i.data()['name'] ?? "User";
  //               setState(() {
  //                 _isEmergency = false;
  //               });
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text("$responderName Responded"),
  //                 ),
  //               );
  //             }
  //           });
  //         }

  //         if (attempt == 3) {
  //           setState(() {
  //             _isEmergency = false;
  //           });
  //         }
  //       } catch (e) {
  //         print("Exception ${e}");
  //       }
  //     }
  //   }
  // }
}
