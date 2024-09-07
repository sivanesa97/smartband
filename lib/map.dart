import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapSelectionScreen extends StatefulWidget {
  final LatLng? defaultLocation;
  const MapSelectionScreen({required this.defaultLocation, Key? key})
      : super(key: key);

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedLocation;
  double _zoomLevel = 13.0;

  void _animateToLocation(LatLng location, double zoom) {
    _mapController.move(location, zoom);
  }

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.defaultLocation;
  }

  void _onTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      // _mapController.move(location,
      //     _mapController.zoom); // Move without changing the zoom level
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedLocation);
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final location = data[0];
        final lat = double.parse(location['lat']);
        final lon = double.parse(location['lon']);
        final newLocation = LatLng(lat, lon);

        setState(() {
          _selectedLocation = newLocation;
          _animateToLocation(newLocation, _zoomLevel);
        });
      } else {
        // Handle case where no results are found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results found for "$query"')),
        );
      }
    } else {
      // Handle error in fetching data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search for "$query"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter =
        _selectedLocation ?? LatLng(7.032732, 79.909209);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _confirmSelection,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city',
                fillColor: Colors.white,
                filled: true,
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchLocation(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FlutterMap(
        mapController: _mapController, // Pass the MapController to FlutterMap
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: _zoomLevel,
          onTap: _onTap,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              if (_selectedLocation !=
                  null) // Check if _selectedLocation is not null
                Marker(
                  point: _selectedLocation!,
                  width: 80.0,
                  height: 80.0,
                  child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
