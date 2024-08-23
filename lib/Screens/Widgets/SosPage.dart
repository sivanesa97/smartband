import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  _SOSPageState createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  int countdown = 30;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    startCountdown();
  }

  Future<void> _initializeFirebase() async {
    // if (!Firebase.apps.any((element) => element.name == '[DEFAULT]')) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    // }
  }

  int endTime = 0;
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  void playSound() async {
    await audioPlayer.setReleaseMode(ReleaseMode.loop);
    await audioPlayer.setVolume(1.0); // Ensure volume is set to max
    await audioPlayer.play(AssetSource("sounds/security_alarm.mp3"));
    isPlaying = true;

    // Stop the sound after 1 minute
    Future.delayed(Duration(seconds: 30), () {
      if (isPlaying) {
        audioPlayer.stop();
        FlutterOverlayWindow.closeOverlay();
      }
    });
  }

  void stopSound() async {
    await audioPlayer.stop();
    isPlaying = false;
  }

  void startSOS() {
    endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 5;
    playSound();
  }

  void startCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        if (countdown > 0) {
          setState(() {
            countdown--;
          });
          startCountdown();
        } else {
          if (mounted) {
            FlutterOverlayWindow.closeOverlay();
            Navigator.pop(context);
          }
        }
      }
    });
  }

  void handleUpdate() async {
    await _initializeFirebase();
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("emergency_alerts")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();
        if (doc.exists) {
          await FirebaseFirestore.instance
              .collection("emergency_alerts")
              .doc(doc.id)
              .update({
            "responseStatus": true,
            "response": "Accepted",
            "timestamp": FieldValue.serverTimestamp()
          });
          await FirebaseFirestore.instance
              .collection("emergency_alerts")
              .doc(doc.id)
              .collection(currentUser.uid)
              .add({
            "responseStatus": true,
            "response": "Accepted",
            "timestamp": FieldValue.serverTimestamp()
          });
        }

        print("Emergency alerts updated successfully");
      } catch (e) {
        print("Error updating emergency alerts: $e");
      }
    } else {
      print("No user is currently signed in");
    }

    // Close the overlay window after updating
    FlutterOverlayWindow.closeOverlay();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/monitoring_person_background.png'), // Replace with your image path
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SOS Emergency Service',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'We’re here to provide users with rapid access to essential emergency services during critical situations.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Emergency Call',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      countdown.toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    print("closing overlay");
                    handleUpdate();
                    FlutterOverlayWindow.closeOverlay();

                    stopSound();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 142, 147, 238),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 75, vertical: 15),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    print("closing overlay");
                    FlutterOverlayWindow.closeOverlay();
                    stopSound();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    'Skip For Now',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          )
          // Gradient overlay
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //       colors: [
          //         Colors.black.withOpacity(0.3),
          //         Colors.black.withOpacity(0.3),
          //       ],
          //     ),
          //   ),
          // ),
          // Content
        ],
      ),
    );
  }
}
