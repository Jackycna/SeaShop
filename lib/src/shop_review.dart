import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewUploadPage extends StatefulWidget {
  final String ownerId;
  final String? userId;

  const ReviewUploadPage(
      {super.key, required this.ownerId, required this.userId});

  @override
  ReviewUploadPageState createState() => ReviewUploadPageState();
}

class ReviewUploadPageState extends State<ReviewUploadPage> {
  int rating = 0;
  TextEditingController reviewController = TextEditingController();
  bool isLoading = true;
  String? userName;
  String? shopName;
  String? reviewId; // Store review document ID if it exists
  String? _shopImageUrl; // Store shop image URL

  @override
  void initState() {
    super.initState();
    fetchUserName();
    checkExistingReview();
    fetchShopImage();
  }

  Future<void> fetchUserName() async {
    if (widget.userId == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc[
              'name']; // Assuming 'name' is the field for the user's name
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching user data: $e")),
        );
      }
    }
  }

  Future<void> fetchShopImage() async {
    try {
      DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
          .collection('owners')
          .doc(widget.ownerId)
          .get();
      if (ownerDoc.exists) {
        setState(() {
          _shopImageUrl = ownerDoc['profileImage'];
          shopName = ownerDoc[
              'displayName']; // Assuming 'imageUrl' is the field for shop image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching shop image: $e")),
        );
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkExistingReview() async {
    if (widget.userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('owners')
          .doc(widget.ownerId)
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .limit(1)
          .get();

      if (reviewSnapshot.docs.isNotEmpty) {
        var reviewData = reviewSnapshot.docs.first;
        setState(() {
          reviewId = reviewData.id;
          rating = reviewData['rating'];
          reviewController.text = reviewData['review'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking existing review: $e")),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (rating == 0 || reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a rating and review")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (reviewId == null) {
        // New review
        DocumentReference newReviewRef = await FirebaseFirestore.instance
            .collection('owners')
            .doc(widget.ownerId)
            .collection('reviews')
            .add({
          'userId': widget.userId,
          'userName': userName ?? "Anonymous",
          'rating': rating,
          'review': reviewController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          reviewId = newReviewRef.id;
        });
      } else {
        // Update existing review
        await FirebaseFirestore.instance
            .collection('owners')
            .doc(widget.ownerId)
            .collection('reviews')
            .doc(reviewId)
            .update({
          'rating': rating,
          'review': reviewController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully")),
        );

        Navigator.pop(context);
      } // Navigate back after submission
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting review: $e")),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: Text(
          shopName ?? "Shop Review",
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF003780)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Image
                    _shopImageUrl != null
                        ? Center(
                            child: Image.network(
                              _shopImageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.fill,
                            ),
                          )
                        : Center(
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Center(child: Text("Shop Image")),
                            ),
                          ),
                    const SizedBox(height: 10),

                    // Instruction Text
                    const Text(
                      "Your review will help other users find a great service.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF003780)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF003780)),
                    const SizedBox(height: 20),

                    // If review exists, show it instead of input fields
                    if (reviewId != null) ...[
                      const Text(
                        "Your Review:",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003780)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            color: index < rating ? Colors.amber : Colors.grey,
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF003780)),
                        ),
                        child: Text(
                          reviewController.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFF003780), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Thank you for your review',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF003780),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // If no review exists, show input fields
                      const Text(
                        "Rate your experience:",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003780)),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              color:
                                  index < rating ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      TextField(
                        controller: reviewController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Write your review...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003780),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Submit Review",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
