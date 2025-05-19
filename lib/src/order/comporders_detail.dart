import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sea_shop/localization/localization_service.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({required this.order, super.key});

  @override
  OrderDetailPageState createState() => OrderDetailPageState();
}

class OrderDetailPageState extends State<OrderDetailPage> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isFeedbackSubmitted = false;
  bool _hasExistingFeedback = false;
  bool _isSubmitting = false;
  bool _isSubmittinga = false;
  bool _isButtonPressed = false;

  // Function to check if feedback already exists
  Future<void> _checkForExistingFeedback() async {
    setState(() {
      _isSubmittinga = true;
    });
    try {
      final feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('orderId', isEqualTo: widget.order['orderId'])
          .get();

      if (feedbackSnapshot.docs.isNotEmpty) {
        setState(() {
          _hasExistingFeedback = true;
        });
      }
    } catch (e) {
      // print('Error checking feedback: $e');
    }
    setState(() {
      _isSubmittinga = false;
    });
  }

  // Function to upload the feedback to Firestore
  Future<void> _submitFeedback() async {
    if (_feedbackController.text.isEmpty) {
      // Show an alert message if feedback is empty
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(LocalizationService().translate('error')),
            content: Text(LocalizationService().translate('emptyfeed')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the alert dialog
                },
                child: Text(LocalizationService().translate('ok')),
              ),
            ],
          );
        },
      );
      return; // Exit early if feedback is empty
    }

    try {
      setState(() {
        _isSubmitting = true; // Show the loading indicator
      });
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'userId': widget.order['customerId'],
        'orderId': widget.order['orderId'],
        'Item': widget.order['fishName'],
        'name': widget.order['Name'],
        'delivery Person': widget.order['deliveredBy'],
        'feedback': _feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isFeedbackSubmitted = true;
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false; // Hide the loading indicator on error
      });
      //print('Error uploading feedback: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkForExistingFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de), // Light background for contrast
      appBar: AppBar(
        title: Text(
          LocalizationService().translate('orderdetails'),
          style: const TextStyle(
            color: Color(0xFF003780),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFEae6de),
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
      ),
      body: _isSubmittinga
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🐟 Order Details Card
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizationService().translate('fishname2'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003780),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${widget.order['fishName'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Image Section with Shadow
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(2, 4),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/images/success.png',
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 📌 Order Summary with Divider
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              LocalizationService().translate('corderdialouge'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003780),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Divider(thickness: 1.2),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🌟 Feedback Section
                    if (_hasExistingFeedback == false)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService().translate('feedback'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003780),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            LocalizationService().translate('feed2'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 📝 Feedback TextField
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: TextField(
                                controller: _feedbackController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText:
                                      LocalizationService().translate('feed3'),
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF003780),
                                ),
                                enabled: !_isFeedbackSubmitted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ✅ Animated Submit Button
                          if (_isSubmitting)
                            const Center(child: CircularProgressIndicator())
                          else
                            Center(
                              child: GestureDetector(
                                onTapDown: (_) =>
                                    setState(() => _isButtonPressed = true),
                                onTapUp: (_) =>
                                    setState(() => _isButtonPressed = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  transform: _isButtonPressed
                                      ? Matrix4.identity()
                                      : Matrix4.identity(),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF003780),
                                        Color(0xFF001F4D)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                        offset: const Offset(2, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _submitFeedback,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      LocalizationService()
                                          .translate('submitfeedback'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    if (_isFeedbackSubmitted)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          LocalizationService().translate('thankfeed'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF003780),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
