// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place_plus/google_place_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator package
import 'package:flutter/services.dart';
import 'package:sea_shop/localization/localization_service.dart';

class LocationPickerPage extends StatefulWidget {
  final Function(String) onLocationSelected;
  final String? initialAddress;

  const LocationPickerPage({
    super.key,
    required this.onLocationSelected,
    this.initialAddress,
  });

  @override
  LocationPickerPageState createState() => LocationPickerPageState();
}

class LocationPickerPageState extends State<LocationPickerPage> {
  late GoogleMapController mapController;
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  LatLng _selectedLocation = const LatLng(0, 0);
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(
        "AIzaSyApo_S_3M7xDCzgddlyLFtn8lQULF2XXQs"); // Replace with your API key
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      // Use Geocoding API to get coordinates from address
      var result =
          await googlePlace.search.getTextSearch(widget.initialAddress!);
      if (result != null &&
          result.results != null &&
          result.results!.isNotEmpty) {
        final location = result.results!.first.geometry!.location!;
        setState(() {
          _selectedLocation = LatLng(location.lat!, location.lng!);
          _markers.add(Marker(
            markerId: const MarkerId('initialLocation'),
            position: _selectedLocation,
          ));
          _isLoading = false;
        });
      }
    } else {
      // Fall back to getting current location
      await _checkPermissionsAndLoadCurrentLocation();
    }
  }

  Future<void> _checkPermissionsAndLoadCurrentLocation() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      await _getCurrentLocation();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          );
          _markers.clear();
          _markers.add(Marker(
            markerId: const MarkerId('currentLocation'),
            position: _selectedLocation,
          ));
          _isLoading = false;
        });
        mapController.moveCamera(CameraUpdate.newLatLng(_selectedLocation));
      }
    } on PlatformException catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.moveCamera(CameraUpdate.newLatLng(_selectedLocation));
  }

  void _confirmSelection() {
    widget.onLocationSelected(
        '${_selectedLocation.latitude},${_selectedLocation.longitude}');
    Navigator.pop(context);
  }

  void _useCurrentLocation() {
    _getCurrentLocation();
  }

  void _onSearchChanged(String value) async {
    if (value.isNotEmpty && googlePlace != null) {
      var result = await googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null) {
        setState(() {
          predictions = result.predictions!;
        });
      }
    } else {
      setState(() {
        predictions = [];
      });
    }
  }

  Future<void> _selectPlace(String placeId) async {
    var details = await googlePlace.details.get(placeId);
    if (details != null && details.result != null && mounted) {
      final location = details.result!.geometry!.location!;
      setState(() {
        _selectedLocation = LatLng(location.lat!, location.lng!);
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('selectedLocation'),
          position: _selectedLocation,
        ));
        predictions = [];
        _searchController.clear();
      });
      mapController.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: Text(LocalizationService().translate('picklocation'),
            style: const TextStyle(
                color: Color(0xFF003780), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 17.0,
                  ),
                  markers: _markers,
                  onTap: (LatLng location) {
                    setState(() {
                      _selectedLocation = location;
                      _markers.clear();
                      _markers.add(Marker(
                        markerId: const MarkerId('selectedLocation'),
                        position: location,
                      ));
                    });
                  },
                  mapType: MapType.hybrid,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: LocalizationService().translate('search'),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  predictions = [];
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      if (predictions.isNotEmpty)
                        Container(
                          color: Colors.white,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: predictions.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title:
                                    Text(predictions[index].description ?? ""),
                                onTap: () {
                                  _selectPlace(predictions[index].placeId!);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 80,
                  left: 100,
                  right: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003780)),
                    onPressed: _useCurrentLocation,
                    child: Text(
                        LocalizationService().translate('currentlocation'),
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 100,
                  right: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003780)),
                    onPressed: _confirmSelection,
                    child: Text(
                      LocalizationService().translate('confirm'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
