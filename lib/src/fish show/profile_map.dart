import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place_plus/google_place_plus.dart';
import 'package:sea_shop/localization/localization_service.dart';

class MapPickerPage extends StatefulWidget {
  final String? initialPosition;

  const MapPickerPage({super.key, this.initialPosition});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _currentPosition;
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  List<AutocompletePrediction> predictions = [];
  final TextEditingController _searchController = TextEditingController();
  final googlePlace = GooglePlace(
      "AIzaSyApo_S_3M7xDCzgddlyLFtn8lQULF2XXQs"); // Replace with your API key
  late LatLng _selectedLocation;
  bool isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition != null
        ? _parseLatLng(widget.initialPosition!)
        : const LatLng(37.7749, -122.4194); // Default to San Francisco
    _selectedLocation = _currentPosition;

    // Initial marker for the starting position
    _markers.add(
      Marker(
        markerId: const MarkerId('initial-location'),
        position: _currentPosition,
        infoWindow: const InfoWindow(title: 'Initial Location'),
      ),
    );
  }

  LatLng _parseLatLng(String position) {
    final parts = position.split(',');
    return LatLng(
      double.parse(parts[0]),
      double.parse(parts[1]),
    );
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      isLoading = true;
      _selectedLocation = position; // Update selected location
      _markers = {
        Marker(
          markerId: const MarkerId('selected-location'),
          position: _selectedLocation, // Use the updated location
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });

    // Optionally animate the camera to the tapped location
    mapController.animateCamera(CameraUpdate.newLatLng(position));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          isLoading = true;
          _currentPosition = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentPosition;
          _markers = {
            Marker(
              markerId: const MarkerId('current-location'),
              position: _currentPosition,
              infoWindow: const InfoWindow(title: 'Current Location'),
            ),
          };
        });
      }

      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onSearchChanged(String value) async {
    if (value.isNotEmpty) {
      try {
        var result = await googlePlace.autocomplete.get(value);
        setState(() {
          predictions = result?.predictions ?? [];
        });
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching predictions: $e");
        }
      }
    } else {
      setState(() {
        predictions = [];
      });
    }
  }

  Future<void> selectPlace(String placeId) async {
    try {
      var details = await googlePlace.details.get(placeId);
      if (details != null && details.result != null && mounted) {
        final location = details.result!.geometry!.location!;
        setState(() {
          _selectedLocation = LatLng(location.lat!, location.lng!);
          _markers = {
            Marker(
              markerId: const MarkerId('selected-location'),
              position: _selectedLocation,
              infoWindow: const InfoWindow(title: 'Selected Location'),
            ),
          };
          predictions = [];
          _searchController.clear();
        });

        // Animate camera to the new selected location
        mapController.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('picklocation'),
          style: const TextStyle(
              color: Color(0xFF003780), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 18,
                  ),
                  mapType: MapType.hybrid,
                  markers: _markers,
                  onTap: _onMapTapped,
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                ),
                // Search bar on top
                Positioned(
                  top: 20,
                  left: 15,
                  right: 15,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: LocalizationService().translate('search'),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003780),
                          fontSize: 15),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEae6de)),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                // Display search results
                Positioned(
                  top: 100,
                  left: 15,
                  right: 15,
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: predictions.length,
                      itemBuilder: (context, index) {
                        final prediction = predictions[index];
                        return Card(
                          color: Colors.white, // Set background color to white
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              prediction.description ?? '',
                              style: const TextStyle(
                                color: Colors.black, // Set text color to black
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () => selectPlace(prediction.placeId!),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Loading indicator

                // Confirm Location Button
                Positioned(
                  bottom: 60,
                  right: 110,
                  left: MediaQuery.of(context).size.width * 0.25,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context,
                          '${_selectedLocation.latitude},${_selectedLocation.longitude}');
                    },
                    child: Text(
                      LocalizationService().translate('confirm'),
                      style: const TextStyle(
                          color: Color(0xFF003780),
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
                // Floating action button for current location
                Positioned(
                  bottom: 150,
                  left: 90,
                  right: 110,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003780)),
                    onPressed: _getCurrentLocation,
                    child: Text(
                      LocalizationService().translate('currentlocation'),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
