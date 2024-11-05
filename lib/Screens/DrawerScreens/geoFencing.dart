import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smartband/Screens/Widgets/loading.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/map.dart';
import 'package:http/http.dart' as http;

class GeoFencing extends ConsumerStatefulWidget {
  const GeoFencing({super.key});

  @override
  ConsumerState<GeoFencing> createState() => _ProfilepageState();
}

class _ProfilepageState extends ConsumerState<GeoFencing> {
  bool isEdit = false;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minKmController = TextEditingController();

  String _selectedGender = "";
  DateTime? _selectedDate;
  LatLng? defaultLocation;

  Future<String> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    Placemark place = placemarks[0];
    return place.locality ?? 'Unknown location';
  }

  Future<void> getData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      try {
        final data = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .get();
        if (data.exists) {
          var data1 = data.data();
          setState(() {
            _minKmController.text = (data1?['minimum_km'] ?? 0).toString();
            if (data1?['home_location'] is GeoPoint) {
              GeoPoint geoPoint = data1?['home_location'];
              _locationController.text =
                  formatLatLng(LatLng(geoPoint.latitude, geoPoint.longitude));
              defaultLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
            } else {
              _locationController.text = data1?['home_location'] ?? '';
            }
          });
        } else {
          print('Document does not exist');
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
    } else {
      print('User is not authenticated');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  String formatLatLng(LatLng latLng) {
    String latitude = latLng.latitude.toStringAsFixed(6);
    String longitude = latLng.longitude.toStringAsFixed(6);
    String latDirection = latLng.latitude >= 0 ? 'N' : 'S';
    String longDirection = latLng.longitude >= 0 ? 'E' : 'W';

    return '$latitude° $latDirection, $longitude° $longDirection';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: GestureDetector(
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Icon(Icons.arrow_back),
          ),
        ),
        title: Text("Edit Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: user_data.when(
            data: (data) {
              List<String> relations = [];
              if (data != null) {
                relations = data.relations;
              }
              return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Container(
                    // height: height,
                    child: Column(
                      children: [
                        Center(
                          child: Icon(
                            Icons.account_circle,
                            color: Color.fromRGBO(0, 83, 188, 1),
                            size: width * 0.35,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Location",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _locationController,
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.map),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MapSelectionScreen(
                                                        defaultLocation:
                                                            defaultLocation),
                                              ),
                                            );
                                            if (result != null) {
                                              setState(() {
                                                _locationController.text =
                                                    formatLatLng(result);
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _locationController.text,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontSize: width * 0.05,
                                          color: Colors.black),
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Geo Fencing Limit KM",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _minKmController,
                                      decoration: InputDecoration(
                                        hintText:
                                            data?.minimum_km.toString() ?? '',
                                      ),
                                      keyboardType: TextInputType
                                          .number, // To input numbers
                                    )
                                  : Text(
                                      _minKmController.text,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: width * 0.05),
                                    ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Center(
                            child: Container(
                          width: width * 0.9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color.fromRGBO(0, 83, 188, 1),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              setState(() {
                                isEdit = !isEdit;
                              });
                              if (!isEdit) {
                                GeoPoint convertToGeoPoint(String location) {
                                  RegExp regExp = RegExp(
                                      r'(\d+\.\d+)° ([NS]), (\d+\.\d+)° ([EW])');
                                  Match? match = regExp.firstMatch(location);

                                  if (match != null) {
                                    double latitude =
                                        double.parse(match.group(1)!);
                                    if (match.group(2) == 'S')
                                      latitude = -latitude;

                                    double longitude =
                                        double.parse(match.group(3)!);
                                    if (match.group(4) == 'W')
                                      longitude = -longitude;

                                    return GeoPoint(latitude, longitude);
                                  }

                                  throw FormatException(
                                      'Invalid location format');
                                }

                                GeoPoint geoPoint =
                                    convertToGeoPoint(_locationController.text);
                                double minimumKm =
                                    double.parse(_minKmController.text);
                                FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .update({
                                  "home_location": geoPoint,
                                  "minimum_km": minimumKm,
                                });
                                getData();
                                final response = await http.post(
                                  Uri.parse(
                                      "https://snvisualworks.com/public/api/auth/register"),
                                  headers: <String, String>{
                                    'Content-Type':
                                        'application/json; charset=UTF-8',
                                  },
                                  body: jsonEncode(<String, dynamic>{
                                    'geoLocation': _locationController.text,
                                    'minimum_km': _minKmController.text,
                                  }),
                                );
                                print(response.statusCode);
                              }
                            },
                            child: !isEdit
                                ? Text(
                                    'Edit',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.05),
                                  )
                                : Text(
                                    'Save details',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.05),
                                  ),
                          ),
                        )),
                      ],
                    ),
                  ));
            },
            error: (error, StackTrace) {
              return Text("Error");
            },
            loading: () {
              return GradientLoadingIndicator();
            },
          ),
        ),
      ),
    );
  }
}
