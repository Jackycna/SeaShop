// ignore_for_file: sized_box_for_whitespace
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sea_shop/localization/localization_service.dart';
import 'package:sea_shop/src/afish%20types/chopped/chopped_payment.dart';
import 'package:sea_shop/src/styles/app_bar_style.dart';

class ChoppedCheckoutPage extends StatefulWidget {
  final String fishName;
  final double fishPricePerKg;
  final String cartItemId;
  final String ownerId;
  final String image;
  final String type;
  final double distance;
  final List<int> availableGrams;

  final bool prepare;

  const ChoppedCheckoutPage({
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

class CheckoutPageState extends State<ChoppedCheckoutPage> {
  bool isLoading = true;
  List<int> selectedGram = [];
  double? updatedPrice;
  bool priceVisible = false;
  String? fishName;
  String? choppedDescription;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        title: Text(
          LocalizationService().translate(''),
          style: AppTextStyles.appBarTitleStyle,
        ),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(10.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with loading indicator
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            widget.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200, // Set a fixed height
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child; // Image loaded successfully
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.black12,
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.red, size: 50),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.fishName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003780),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price Section
                    if (priceVisible) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Price Icon
                            const SizedBox(width: 2),
                            Text(
                              LocalizationService().translate('price'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003780),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            isLoading
                                ? const CircularProgressIndicator()
                                : Row(
                                    children: [
                                      Text(
                                        '₹${(updatedPrice! * 1.2).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '₹${updatedPrice!.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF003780),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Offer Badge with Animation
                                      Bounce(
                                        infinite: true,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                    0.8), // Shadow color
                                                blurRadius:
                                                    6, // Soft blur effect
                                                spreadRadius:
                                                    2, // Slight spread
                                                offset: const Offset(
                                                    0, 3), // Downward shadow
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "20% OFF",
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

                    const SizedBox(height: 30),

                    // Weight Selection
                    const Row(
                      children: [
                        Icon(Icons.balance,
                            color: Color(0xFF003780)), // Weight Icon
                        SizedBox(width: 8),
                        Text(
                          "Select Weight (grams):",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003780),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      children: widget.availableGrams.map((gram) {
                        bool isSelected = selectedGram.contains(gram);
                        return ChoiceChip(
                          label: Text("$gram g"),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedGram.add(gram); // Add selected gram
                              } else {
                                selectedGram
                                    .remove(gram); // Remove if deselected
                              }
                            });
                            updatePrice(); // Update price when selection changes
                          },
                          selectedColor: const Color(0xFF003780),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    // Time Slot Selection

                    // Chopping Preference Section
                    if (widget.type == 'Fishes') ...[
                      const Text(
                        "Chopping Preference",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003780),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cut,
                                color: Color(0xFF003780), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Fillet, Whole, Slices...",
                                  hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.2)),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    choppedDescription = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),
                    // Add this inside your StatefulWidget

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTapDown: (_) => setState(() =>
                                  isPressed = true), // Button press effect
                              onTapUp: (_) => setState(() => isPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: isPressed
                                    ? Matrix4
                                        .identity() // Slight shrink effect when pressed
                                    : Matrix4.identity(),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      25), // Rounded corners
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF003780),
                                      Color(0xFF0077B6)
                                    ], // Gradient effect
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _navigateToPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors
                                        .transparent, // Transparent to use gradient
                                    shadowColor: Colors
                                        .transparent, // Removes default shadow
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    LocalizationService().translate('continue'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
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
    if (updatedPrice != null) {
      setState(() {
        String description =
            choppedDescription != null && choppedDescription!.isNotEmpty
                ? " (${choppedDescription!})"
                : "";
        fishName =
            "${widget.fishName.split(' ')[0]} $selectedGram g $description";
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChoppedPaymentPage(
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

  bool isTimeSlotPassed(String timeSlot) {
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm a');

    final times = timeSlot.split(' - ');
    if (times.length == 2) {
      final startTime = formatter.parse(times[0]); // Start time
      final endTime = formatter.parse(times[1]); // End time

      final startDateTime = DateTime(
          now.year, now.month, now.day, startTime.hour, startTime.minute);
      final endDateTime =
          DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

      // Check if the slot should be closed (not within the valid range)
      return now.isBefore(startDateTime) || now.isAfter(endDateTime);
    }
    return true; // If the format is incorrect, treat it as passed/invalid
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

  Future<void> loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updatePrice() async {
    setState(() {
      isLoading = true;
      priceVisible = false;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (selectedGram.isEmpty) {
      // If no grams are selected, hide the price
      if (mounted) {
        setState(() {
          updatedPrice = 0; // Reset price
          isLoading = false;
          priceVisible = false; // Hide price section
        });
      }
      return;
    }

    int totalGrams = selectedGram.fold(0, (sum, gram) => sum + gram);
    double newPrice = (widget.fishPricePerKg * totalGrams) / 1000;

    if (mounted) {
      setState(() {
        updatedPrice = newPrice;
        isLoading = false;
        priceVisible = true;
      });
    }
  }

  Widget buildTimeSlotRow({
    required String title,
    required String? selectedValue,
    required List<String> timeSlots,
    required ValueChanged<String?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time,
                color: Color(0xFF003780)), // Clock Icon
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003780)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two slots per row
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 4, // Adjust the height-to-width ratio
          ),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = timeSlots[index];
            final isPassed = isTimeSlotPassed(timeSlot);
            final isSelected = selectedValue == timeSlot;

            return GestureDetector(
              onTap: isPassed
                  ? null
                  : () {
                      onSelected(timeSlot);
                    },
              child: Stack(
                children: [
                  // Time slot container
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF003780)
                          : Colors.white, // Highlight if selected
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF003780)
                            : const Color(0xFF003780).withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        timeSlot,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // Blur overlay if the time slot is passed
                  if (isPassed)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // Blur overlay
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          LocalizationService().translate('passed'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
