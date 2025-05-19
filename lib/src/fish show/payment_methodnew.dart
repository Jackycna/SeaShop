import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sea_shop/src/fish%20show/payment_success.dart';

class PaymentMethodPage extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  final String ownerId;

  const PaymentMethodPage(
      {super.key, required this.orderDetails, required this.ownerId});

  @override
  PaymentMethodPageState createState() => PaymentMethodPageState();
}

class PaymentMethodPageState extends State<PaymentMethodPage> {
  bool isLoading = true;
  bool cashOnDelivery = false;
  bool _isCodPressed = false;
  bool _isPayNowPressed = false;
  late Razorpay _razorpay;
  String? orderId;
  bool claimed = false;

  @override
  void initState() {
    super.initState();
    fetchOwnerDetails();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  Future<void> fetchOwnerDetails() async {
    try {
      DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
          .collection('owners')
          .doc(widget.ownerId)
          .get();

      if (ownerDoc.exists) {
        setState(() {
          cashOnDelivery = ownerDoc['cashondel'] ?? false;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching owner details: $e");
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startPayment() async {
    double totalPrice = widget.orderDetails['totalPrice'];
    double deliveryCharge = widget.orderDetails['deliveryCharge'];
    double platformFee = 10.0;

    double amountToMerchant = totalPrice + deliveryCharge;

    var options = {
      'key': 'rzp_live_neChPGiLYuVmsW',
      'amount': (amountToMerchant + platformFee) * 100,
      'currency': 'INR',
      'name': 'Sea Shop',
      'description': 'Order Payment',
      'prefill': {'contact': '9344091532', 'email': 'trens033@gmail.com'},
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _saveOrderDetails('Online Payment');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => PaymentSuccess(
                ownerId: widget.ownerId,
                userId: FirebaseAuth.instance.currentUser?.uid)),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment failed. Try again!')),
    );
  }

  Future<void> _saveOrderDetails(String status) async {
    setState(() {
      isLoading = true;
    });
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      CollectionReference ordersRef =
          FirebaseFirestore.instance.collection('orders');
      DocumentReference orderDoc = ordersRef.doc();
      String orderId = orderDoc.id;
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      double totalPrice = widget.orderDetails['totalPrice'];
      double deliveryCharge = widget.orderDetails['deliveryCharge'];

      double platformFee = 10.0;
      double finalTotal = totalPrice + deliveryCharge + platformFee;

      await orderDoc.set({
        ...widget.orderDetails,
        'payment_method': status,
        'orderId': orderId,
        'order_date': currentDate,
        'userId': currentUser.uid,
        'total_price': finalTotal,
        'claimed': claimed,
        'expiresAt': DateTime.now().add(const Duration(minutes: 30)),
      });
      if (status == 'Cash on Delivery') {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => PaymentSuccess(
                    ownerId: widget.ownerId,
                    userId: FirebaseAuth.instance.currentUser?.uid)),
          );
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.orderDetails['totalPrice'];
    double deliveryCharge = widget.orderDetails['deliveryCharge'];
    double platformFee = 10.0;
    double finalTotal = totalPrice + deliveryCharge + platformFee;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              '',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF003780)),
            ),
            backgroundColor: const Color(0xFFEae6de),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          backgroundColor: const Color(0xFFEae6de),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Image.asset(
                'assets/images/112.png',
                width: 100,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart,
                            color: Color(0xFF003780), size: 25),
                        const SizedBox(width: 8),
                        const Text('Total Amount',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        Text('₹${totalPrice.toInt()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining,
                            color: Color(0xFF003780), size: 25),
                        const SizedBox(width: 8),
                        const Text('Delivery Charge',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        Text('₹${deliveryCharge.toInt()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Color(0xFF003780), size: 25),
                        const SizedBox(width: 8),
                        const Text('Platform Fee',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        Text('₹${platformFee.toInt()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.attach_money,
                            color: Color(0xFF003780), size: 25),
                        const SizedBox(width: 8),
                        const Text('Final Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        Text('₹${finalTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Cash on Delivery Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose Payment Option',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (cashOnDelivery)
                          Expanded(
                            child: GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _isCodPressed = true),
                              onTapUp: (_) =>
                                  setState(() => _isCodPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: _isCodPressed
                                    ? Matrix4.identity()
                                    : Matrix4.identity(),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF003780),
                                      Color(0xFF0077B6)
                                    ],
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
                                  onPressed: () async {
                                    await _saveOrderDetails('Cash on Delivery');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25)),
                                  ),
                                  child: const Text(
                                    'Cash on Delivery',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _isPayNowPressed = true),
                            onTapUp: (_) =>
                                setState(() => _isPayNowPressed = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              transform: _isPayNowPressed
                                  ? Matrix4.identity()
                                  : Matrix4.identity(),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF28A745), Colors.green],
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
                                onPressed: _startPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25)),
                                ),
                                child: const Text(
                                  'Online Payment',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // Loading Indicator
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFEae6de),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
