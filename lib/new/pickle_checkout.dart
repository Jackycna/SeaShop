// ignore_for_file: sized_box_for_whitespace
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/new/pickle_payment.dart';
import 'package:sea_shop/src/styles/app_bar_style.dart';

class PickleCheckout extends StatefulWidget {
  final String fishName;
  final double fishPricePerKg;
  final String cartItemId;
  final String ownerId;
  final String image;
  final String type;
  final double distance;
  final List<int> availableGrams;

  final bool prepare;

  const PickleCheckout({
    super.key,
    required this.fishName,
    required this.fishPricePerKg,
    required this.cartItemId,
    required this.ownerId,
    required this.image,
    required this.prepare,
    required this.type,
    required this.distance,
    required this.availableGrams,
  });

  @override
  CheckoutPageState createState() => CheckoutPageState();
}

class CheckoutPageState extends State<PickleCheckout> {
  String? _selectedTimeSlot;
  bool isLoading = true;
  int? selectedGram;
  double? updatedPrice;
  bool priceVisible = false;
  String? fishName;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updatePrice(int gram) async {
    setState(() {
      isLoading = true;
      selectedGram = gram;
      priceVisible = false;
    });

    await Future.delayed(const Duration(seconds: 1));

    double newPrice = (widget.fishPricePerKg * gram) / 1000;

    if (mounted) {
      setState(() {
        updatedPrice = newPrice;
        isLoading = false;
        priceVisible = true; // Show price after loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('Details'),
          style: AppTextStyles.appBarTitleStyle,
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: isLoading
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003780),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (priceVisible) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white, // Background color
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded corners
                            ),
                            child: Row(
                              children: [
                                Text(
                                  LocalizationService().translate('price'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003780),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                isLoading
                                    ? const CircularProgressIndicator()
                                    : Row(
                                        children: [
                                          // Fake price with strikethrough
                                          Text(
                                            '₹${(updatedPrice! * 1.2).toStringAsFixed(0)}', // Original price assuming 20% off
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                              decoration: TextDecoration
                                                  .lineThrough, // Strikethrough effect
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Discounted price
                                          Text(
                                            '₹${updatedPrice!.toStringAsFixed(0)}', // Final price
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF003780),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Glittering offer percentage
                                          Bounce(
                                            infinite: true,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 3,
                                                      horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                "20% OFF", // Offer percentage
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 30),
                    const Text(
                      "Weight (grams):",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      children: widget.availableGrams.map((gram) {
                        return ChoiceChip(
                          label: Text("$gram g"),
                          selected: selectedGram == gram,
                          onSelected: (bool selected) {
                            if (selected) {
                              updatePrice(gram);
                            }
                          },
                          selectedColor: const Color(0xFF003780),
                          backgroundColor: Colors.grey[300],
                          labelStyle: TextStyle(
                            color: selectedGram == gram
                                ? Colors.white
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),
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
                              child: Text(
                                LocalizationService().translate('continue'),
                                // ignore: prefer_const_constructors
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
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

  void _navigateToPayment() {
    // Check if all required fields are selected or filled
    if (updatedPrice != null) {
      setState(() {
        fishName =
            "${widget.fishName.split(' ')[0]} $selectedGram g"; // Append selected gram
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PicklePayment(
            fishName: fishName!,
            fishPricePerKg: updatedPrice!,
            imageUrl: widget.image,
            ownerId: widget.ownerId,
            fishid: widget.cartItemId,
            type: widget.type,
            distance: widget.distance,
          ),
        ),
      );
    } else if (_selectedTimeSlot == null) {
      showAlertDialog();
    } else {
      showAlertDialog();
    }
  }

  void showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate('missinginfo')),
          content: Text(LocalizationService().translate('missinginfo2')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(LocalizationService().translate('ok')),
            ),
          ],
        );
      },
    );
  }

  bool _isTimeSlotPassed(String timeSlot) {
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm a');

    final times = timeSlot.split(' - ');
    if (times.length == 2) {
      final startTime = formatter.parse(times[0]);
      formatter.parse(times[1]);

      final startDateTime = DateTime(
          now.year, now.month, now.day, startTime.hour, startTime.minute);

      return now.isAfter(startDateTime);
    }
    return false;
  }

  void showAlertDialog2() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate('note')),
          content: Text(LocalizationService().translate('tommorrow')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(LocalizationService().translate('ok')),
            ),
          ],
        );
      },
    );
  }
}
