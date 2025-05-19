import 'dart:ui'; // Import this for BackdropFilter
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pinput/pinput.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  String _verificationId = '';
  bool _otpSent = false;
  bool _isLoading = false;
  bool _otpVerified = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEae6de),
      body: Stack(
        children: [
          // Background Color
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFEae6de),
          ),
          SafeArea(
            child: _isLoading
                ? _buildLoadingIndicator()
                : Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          const SizedBox(
                            height: 80,
                          ),
                          Image.asset('assets/images/lo.png', height: 200),
                          const SizedBox(height: 50),
                          _otpSent
                              ? _buildOtpInputFields()
                              : _buildPhoneInputField(),
                          const SizedBox(height: 50),
                          SizedBox(
                            height: 50,
                            width: 80,
                            child: ElevatedButton(
                              onPressed: _otpSent ? _verifyOTP : _sendOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003780),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(200),
                                ),
                              ),
                              child: Text(
                                _otpSent ? 'Verify OTP' : 'Send OTP',
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontFamily: 'Roboto'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (_otpSent) _buildBackButton(),
        ],
      ),
    );
  }

  // Loading indicator with blurred background
  Widget _buildLoadingIndicator() {
    return Stack(
      children: [
        // Background blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        // Centered loading indicator
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      left: 16,
      top: 16,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF003780)),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
      ),
    );
  }

  Widget _buildPhoneInputField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      focusNode: _phoneFocusNode,
      decoration: InputDecoration(
        labelText: 'Enter Mobile Number',
        labelStyle: const TextStyle(color: Color(0xFF003780)),
        prefixText: _phoneFocusNode.hasFocus ? '+91 ' : '',
        hintStyle: const TextStyle(color: Color(0xFF003780)),
        filled: true,
        fillColor: const Color(0xFF003780).withOpacity(0.1),
        prefixIcon: const Icon(Icons.phone,
            color: Color(0xFF003780)), // Phone icon added
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Color(0xFF003780)),
    );
  }

  Widget _buildOtpInputFields() {
    return Column(
      children: [
        Text(
          'OTP sent to: ${_phoneController.text.trim()}',
          style: const TextStyle(
              fontSize: 16, color: Color(0xFF003780), fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 10),
        Pinput(
          length: 6,
          controller: _otpController,
          onCompleted: (otp) {
            _verifyOTP();
          },
          defaultPinTheme: PinTheme(
            width: 40,
            height: 40,
            textStyle: const TextStyle(fontSize: 18, color: Color(0xFF003780)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF003780)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOTP() async {
    String userInput = _phoneController.text.trim();
    String numericPhoneNumber = userInput.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericPhoneNumber.length != 10) {
      _showAlertDialog('Invalid Phone Number',
          'Please enter a valid 10-digit mobile number.');
      return;
    }

    String phoneNumber = '+91$numericPhoneNumber';

    // Check for test number
    const String testNumber = ''; // Replace with your desired test number
    if (numericPhoneNumber == testNumber) {
      _navigateTouser(); // Navigate directly to user page
      return;
    }

    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _otpVerified = true;
        await _checkUserDataExists();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showAlertDialog('Verification Error',
            e.message ?? 'An error occurred during verification.');
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = false;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
    });
    String otp = _otpController.text.trim();

    if (_verificationId.isNotEmpty && otp.isNotEmpty) {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      try {
        await _auth.signInWithCredential(credential);
        _otpVerified = true;
        await _checkUserDataExists();
        setState(() {
          _otpSent = false;
          _isLoading = false;
        });
      } catch (e) {
        // ignore: avoid_print
        print('Error verifying OTP: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _checkUserDataExists() async {
    if (!_otpVerified) return;

    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        await _updateFCMToken(user.uid);
        _navigateToHomePage();
      } else {
        await _storeUserData(user.phoneNumber ?? user.uid);
        await _updateFCMToken(user.uid);
        _navigateTouser();
      }
    }
  }

  Future<void> _storeUserData(String phoneNumber) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'phone': phoneNumber,
        'role': 'user',
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<void> _updateFCMToken(String userId) async {
    String? token = await FirebaseMessaging.instance.getToken();
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (token != null && userDoc.exists) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  void _navigateToHomePage() {
    setState(() => _isLoading = false);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _navigateTouser() {
    setState(() => _isLoading = false);
    Navigator.pushNamedAndRemoveUntil(context, '/user', (route) => false);
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
        );
      },
    );
  }
}
