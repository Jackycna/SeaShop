import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:geolocator/geolocator.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({required this.order, super.key});

  @override
  OrderDetailsPageState createState() => OrderDetailsPageState();
}

class OrderDetailsPageState extends State<OrderDetailsPage> {
  int currentStep = 0;
  bool isLoading = true;
  GoogleMapController? mapController;
  String? deliveryPersonId;
  LatLng? deliveryLocation;
  LatLng? userLocation;
  double? distanceInKm;
  late StreamController<Duration> remainingTimeController;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    remainingTimeController = StreamController<Duration>();
    startTimer();
    fetchUserLocation();
    fetchDeliveryPersonId();
  }

  void startTimer() {
    dynamic expiresAtData = widget.order['expiresAt'];

    if (expiresAtData is Timestamp) {
      DateTime expiresAt = expiresAtData.toDate(); // Convert to DateTime

      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTimeController.isClosed) {
          return; // Prevent adding to closed stream
        }

        Duration remaining = expiresAt.difference(DateTime.now());

        if (remaining.isNegative) {
          remainingTimeController.add(Duration.zero);
          timer.cancel();
        } else {
          remainingTimeController.add(remaining);
        }
      });
    } else {
      remainingTimeController.add(Duration.zero);
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel(); // Stop the timer before disposing
    remainingTimeController.close(); // Now it's safe to close the stream
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style:
              TextStyle(color: Color(0xFF003780), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderDetailsBox(),
                        const SizedBox(height: 20),
                        StreamBuilder<Duration>(
                          stream: remainingTimeController.stream,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text("Calculating time...");
                            }

                            Duration remaining = snapshot.data!;
                            String formattedTime = remaining.inSeconds > 0
                                ? "${remaining.inHours.toString().padLeft(2, '0')}:"
                                    "${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:"
                                    "${(remaining.inSeconds % 60).toString().padLeft(2, '0')}"
                                : "00:00:00";

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              decoration: BoxDecoration(
                                color: Colors.white, // Light blue background
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black, // Shadow color
                                    spreadRadius:
                                        2, // How much the shadow spreads
                                    blurRadius: 5, // How soft the shadow is
                                    offset: Offset(1, 3), // X and Y offset
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timer,
                                      color: Color(0xFF003780), size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Delivery in: $formattedTime",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003780),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildCustomStepper(),
                        const SizedBox(height: 20),
                        if (widget.order['status'] == 'Picked' &&
                            deliveryLocation != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    GoogleMap(
                                      mapType: MapType.hybrid,
                                      initialCameraPosition: CameraPosition(
                                        target: deliveryLocation!,
                                        zoom: 16,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId:
                                              const MarkerId("deliveryPerson"),
                                          position: deliveryLocation!,
                                          icon: BitmapDescriptor
                                              .defaultMarkerWithHue(
                                            BitmapDescriptor.hueBlue,
                                          ),
                                        ),
                                      },
                                      onMapCreated:
                                          (GoogleMapController controller) {
                                        mapController = controller;
                                      },
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.directions_bike,
                                                color: Colors.blueAccent),
                                            const SizedBox(width: 5),
                                            Text(
                                              "Live Tracking",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              if (distanceInKm != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delivery_dining,
                                          color: Colors.blueAccent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Your order is only ${distanceInKm!.toStringAsFixed(2)} km away!\nIt will reach you soon. 🚀",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> fetchUserLocation() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.order['customerId'])
          .get();

      if (userSnapshot.exists && userSnapshot['address'] != null) {
        String addressString =
            userSnapshot['address']; // Example: "12.9716,77.5946"
        List<String> latLng = addressString.split(',');

        if (latLng.length == 2) {
          double lat = double.parse(latLng[0]);
          double lng = double.parse(latLng[1]);

          setState(() {
            userLocation = LatLng(lat, lng);
          });

          if (kDebugMode) {
            print("User Location: $userLocation");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user location: $e");
      }
    }
  }

  Future<void> fetchDeliveryPersonId() async {
    try {
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order['orderId'])
          .get();

      if (orderSnapshot.exists) {
        var orderData = orderSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          deliveryPersonId =
              (orderData != null && orderData.containsKey('deliveryPersonId'))
                  ? orderData['deliveryPersonId']
                  : null;
        });

        if (kDebugMode) {
          print("Delivery Person ID: $deliveryPersonId");
        }

        if (widget.order['status'] == 'Picked') {
          fetchLiveLocation();
          updateCurrentStep(widget.order['status']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching delivery person ID: $e");
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void updateCurrentStep(String orderStatus) {
    final steps = ['Pending', 'Packed', 'Picked', 'Delivered'];

    currentStep = steps.indexOf(orderStatus);

    if (currentStep == -1) {
      currentStep = 0; // Default to "Pending" if status is unknown
    }

    setState(() {}); // Refresh UI
  }

  void fetchLiveLocation() {
    if (deliveryPersonId == null) return;

    FirebaseFirestore.instance
        .collection('delivery')
        .doc(deliveryPersonId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!.containsKey('latitude') &&
          snapshot.data()!.containsKey('longitude')) {
        double? lat = snapshot['latitude'];
        double? lng = snapshot['longitude'];

        if (lat != null && lng != null) {
          setState(() {
            deliveryLocation = LatLng(lat, lng);
          });

          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLng(deliveryLocation!),
            );
          }

          // Calculate distance
          calculateDistance();
        }
      } else {
        setState(() {
          deliveryLocation = null;
        });
      }
    });
  }

  void calculateDistance() {
    if (userLocation != null && deliveryLocation != null) {
      double distance = Geolocator.distanceBetween(
        userLocation!.latitude,
        userLocation!.longitude,
        deliveryLocation!.latitude,
        deliveryLocation!.longitude,
      );

      setState(() {
        distanceInKm = distance / 1000; // Convert meters to kilometers
      });

      if (kDebugMode) {
        print("Distance: ${distanceInKm!.toStringAsFixed(2)} km");
      }
    }
  }

  void initializeOrderStatus() async {
    final status = widget.order['status'] ?? "Pending";

    switch (status) {
      case "Pending":
        currentStep = 0;
        break;
      case "Packed":
        currentStep = 1;
      case "Picked":
        currentStep = 2;
        break;
      case "Delivered":
        currentStep = 3;
        break;
    }
  }

  Widget _buildOrderDetailsBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildOrderDetailRow(LocalizationService().translate('fishname'),
              widget.order['fishName'] ?? "N/A"),
          const Divider(color: Colors.grey, height: 20),
          buildOrderDetailRow(LocalizationService().translate('totalprice'),
              "₹ ${widget.order['total_price'] ?? '0'}"),
          const Divider(color: Colors.grey, height: 20),
          buildOrderDetailRow(LocalizationService().translate('orderid'),
              " ${widget.order['orderId'] ?? '0'}"),
          const Divider(color: Colors.grey, height: 20),
        ],
      ),
    );
  }

  Widget _buildCustomStepper() {
    final steps = ['Pending', 'Packed', 'Picked', 'Delivered'];
    if (kDebugMode) {
      print("Current Step: $currentStep");
    }

    return Column(
      children: List.generate(
        steps.length,
        (index) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: index <= currentStep
                      ? const Color(0xFF003780)
                      : Colors.grey,
                  child: Icon(
                    Icons.check,
                    color: index >= currentStep
                        ? Colors.white
                        : Colors.transparent,
                    size: 16,
                  ),
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: index < currentStep
                        ? const Color(0xFF003780)
                        : Colors.grey,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: index <= currentStep
                          ? const Color(0xFF003780)
                          : Colors.grey,
                    ),
                  ),
                  if (index ==
                      currentStep) // Show description only for the current step
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        getStepDescription(steps[index]),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.left,
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

  String getStepDescription(String step) {
    switch (step) {
      case "Pending":
        return "Your order is awaiting processing.";
      case "Packed":
        return "Your order has been packed.";
      case "Picked":
        return "Your order has been Picked by a delivery person.";
      case "Delivered":
        return "Your order has been delivered.";

      default:
        return "";
    }
  }

  Widget buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003780),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
