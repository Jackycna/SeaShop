// ignore_for_file: sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:sea_shop/src/fish%20show/payment.dart';

import 'package:sea_shop/src/styles/app_bar_style.dart';

class CheckoutPage extends StatefulWidget {
  final String fishName;
  final double fishPricePerKg;
  final String cartItemId;
  final String ownerId;
  final String shopAddress;
  final String image;
  final String avail;
  final bool prepare;

  const CheckoutPage({
    super.key,
    required this.fishName,
    required this.fishPricePerKg,
    required this.cartItemId,
    required this.ownerId,
    required this.shopAddress,
    required this.image,
    required this.avail,
    required this.prepare,
  });

  @override
  CheckoutPageState createState() => CheckoutPageState();
}

class CheckoutPageState extends State<CheckoutPage> {
  final List<String> _quantities = ['500 g', '750 g', '1000 g', '1500 g'];
  final List<String> _timeSlots = [
    '08:00 AM - 09:00 AM',
    '09:30 AM - 10:30 AM',
    '11:00 AM - 12:00 PM',
    '02:00 PM - 03:00 PM',
    'Tomorrow', // Added tomorrow option
  ];
  final List<String> _preparationOptions = [
    'Chopped fish / வெட்டப்பட்ட மீன்',
  ];

  String? _selectedQuantity;
  String? _selectedTimeSlot;
  String? _selectedPreparation;

  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate a network call or data loading process
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false; // Set loading to false after data is loaded
      });
    }
  }

  // Method to check if a time slot has passed
  bool _isTimeSlotPassed(String timeSlot) {
    // Get current time
    final now = DateTime.now();
    final formatter =
        DateFormat('hh:mm a'); // Use the same format as the time slots

    // Check if "Tomorrow" is selected
    if (timeSlot == 'Tomorrow') {
      return false; // Do not disable this option
    }

    // Split the time range
    final times = timeSlot.split(' - ');
    if (times.length == 2) {
      final startTime = formatter.parse(times[0]);
      final timeComparison = DateTime(
          now.year, now.month, now.day, startTime.hour, startTime.minute);

      // Disable the specific time slot if it has passed
      if (timeSlot == '08:00 AM - 09:00 AM' && timeComparison.isBefore(now)) {
        return true; // Mark this slot as passed
      }

      return timeComparison
          .isBefore(now); // Check if the time is before the current time
    }
    return false;
  }

  void _navigateToPayment() {
    // Check if all required fields are selected or filled
    if (_selectedQuantity != null &&
        _selectedTimeSlot != null &&
        (widget.prepare || _selectedPreparation != null)) {
      // Skip preparation check if `prepare` is true
      double quantity;
      quantity = double.parse(_selectedQuantity!.split(' ')[0]);
      double quantityInt = quantity;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            fishName: widget.fishName,
            fishPricePerKg: widget.fishPricePerKg / 2,
            quantity: quantityInt,
            timeSlot: _selectedTimeSlot!,
            preparation: _selectedPreparation ?? 'No Preparation',
            imageUrl: widget.image,
            ownerId: widget.ownerId,
            shopAddress: widget.shopAddress,
            fishid: widget.cartItemId,
          ),
        ),
      );
    } else {
      _showAlertDialog();
    }
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Missing Information'),
          content: const Text(
              'Please fill in all fields before proceeding to payment.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: AppTextStyles.appBarTitleStyle,
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with loading indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.image,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child; // If the image is loaded, return the child
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.fishName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Price : ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '₹ ${(widget.fishPricePerKg / 2).toStringAsFixed(2)} (500g/கிராம்)',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            Color(0xFF003780), // Attractive color for the price
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quantity Dropdown
                    _buildDropdownRow(
                      title: 'Weight(gram)/எடை(கிராம்):',
                      value: _selectedQuantity,
                      items: _quantities,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedQuantity = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Time Slot Dropdown
                    _buildDropdownRow(
                      title: 'Time slot / நேரம்:',
                      value: _selectedTimeSlot,
                      items: _timeSlots,
                      onChanged: (String? newValue) {
                        setState(() {
                          if (!_isTimeSlotPassed(newValue!)) {
                            _selectedTimeSlot = newValue;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Preparation Type Dropdown
                    if (!widget.prepare) ...[
                      _buildDropdownRow(
                        title: 'Preparation:',
                        value: _selectedPreparation,
                        items: _preparationOptions,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPreparation = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _navigateToPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003780),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 20),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDropdownRow({
    required String title,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Filter out the passed time slots
    final validItems = items.where((item) => !_isTimeSlotPassed(item)).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        DropdownButton<String>(
          value: value,
          hint: const Center(
            child: Text(
              'Select',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          onChanged: (String? newValue) {
            onChanged(newValue);
          },
          items: validItems.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
