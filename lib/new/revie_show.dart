import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  final String ownerId;

  const ReviewPage({super.key, required this.ownerId});

  Stream<List<Map<String, dynamic>>> fetchReviews() {
    return FirebaseFirestore.instance
        .collection('owners')
        .doc(ownerId)
        .collection('reviews')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              var data = doc.data();
              return {
                "userName": data["userName"] ?? "Anonymous",
                "rating": data["rating"] ?? 0,
                "review": data["review"] ?? "",
              };
            }).toList());
  }

  double calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;
    double total = reviews.fold(0, (sum, review) => sum + review["rating"]);
    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEae6de),
        title: const Text(
          "Reviews",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003780)),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No reviews available."));
          }

          List<Map<String, dynamic>> reviews = snapshot.data!;
          double avgRating = calculateAverageRating(reviews);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const Text(
                      "Average Rating",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                      ),
                    ),
                    Text("${avgRating.toStringAsFixed(1)} / 5.0"),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var review = reviews[index];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review["userName"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < review["rating"]
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              review["review"],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
