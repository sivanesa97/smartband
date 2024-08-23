
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeLocationPage extends StatefulWidget {
  @override
  _HomeLocationPageState createState() => _HomeLocationPageState();
}

class _HomeLocationPageState extends State<HomeLocationPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _homeLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getHomeLocationFromFirebase();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _getHomeLocationFromFirebase() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc('user_id').get();
    if (snapshot.exists) {
      setState(() {
        _homeLocation = LatLng(snapshot['lat'], snapshot['lng']);
      });
    } else {
      _homeLocation = _currentLocation;
    }
  }

  Future<void> _saveHomeLocationToFirebase(LatLng location) async {
    await FirebaseFirestore.instance.collection('users').doc('user_id').set({
      'lat': location.latitude,
      'lng': location.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Home Location'),
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _homeLocation ?? _currentLocation!,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _homeLocation != null
                  ? {
                      Marker(
                        markerId: MarkerId('home'),
                        position: _homeLocation!,
                      ),
                    }
                  : {},
              onTap: (LatLng location) {
                setState(() {
                  _homeLocation = location;
                });
                _saveHomeLocationToFirebase(location);
              },
            ),
    );
  }
}