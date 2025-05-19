// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class GoogleMapScreen extends StatefulWidget {
  final LatLng initialPosition;

  const GoogleMapScreen({super.key, required this.initialPosition});

  @override
  GoogleMapScreenState createState() => GoogleMapScreenState();
}

class GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController _controller;
  late LatLng _selectedLocation;
  final MapType _mapType = MapType.normal; // Mutable map type
  late Marker _marker;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialPosition;
    _marker = Marker(
      markerId: const MarkerId("selected_location"),
      position: _selectedLocation,
      infoWindow: const InfoWindow(title: "Selected Location"),
    );
  }

  void _onConfirm() {
    // Confirm and return the selected location
    Navigator.pop(context, _selectedLocation);
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location; // Update the selected location
      _marker = Marker(
        markerId: const MarkerId("selected_location"),
        position: _selectedLocation,
        infoWindow: const InfoWindow(title: "Selected Location"),
      );
    });
  }

  Future<void> _searchPlace() async {
    // Dismiss the keyboard after clicking the search button
    FocusScope.of(context).unfocus();

    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a location name")),
      );
      return;
    }

    try {
      // Get locations from the geocoding API
      List<Location> locations =
          await locationFromAddress(_searchController.text.trim());

      if (locations.isNotEmpty) {
        LatLng newLocation =
            LatLng(locations.first.latitude, locations.first.longitude);

        setState(() {
          _selectedLocation = newLocation;
          _marker = Marker(
            markerId: const MarkerId("selected_location"),
            position: _selectedLocation,
            infoWindow: const InfoWindow(title: "Selected Location"),
          );
        });

        if (_controller != null) {
          // Ensure the controller is ready before calling animateCamera
          _controller.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation, 19.0),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No locations found")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to find the location")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFEae6de),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter place name',
                  filled: true,
                  fillColor: const Color(0xFF003780).withOpacity(0.5),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchPlace, // Trigger search manually
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) => _searchPlace(), // Trigger search on submit
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.initialPosition,
                      zoom: 19.0,
                    ),
                    onTap: _onMapTapped,
                    mapType: _mapType, // Use hybrid view
                    markers: {_marker}, // Add the selected marker
                    onMapCreated: (GoogleMapController controller) {
                      _controller = controller; // Initialize the controller
                    },
                  ),
                  Positioned(
                    bottom: 50,
                    left: MediaQuery.of(context).size.width * 0.5 - 30,
                    child: FloatingActionButton(
                      onPressed: _onConfirm,
                      tooltip: "Confirm Location",
                      child: const Icon(Icons.check),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
