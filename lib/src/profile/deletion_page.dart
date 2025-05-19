import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:pinput/pinput.dart'; // Import Pinput

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  AccountDeletionPageState createState() => AccountDeletionPageState();
}

class AccountDeletionPageState extends State<AccountDeletionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _smsCodeController = TextEditingController();
  String _verificationId = ''; // Store verification ID for OTP
  bool _isLoading = false; // To show a loading indicator during deletion
  bool _isOtpSent = false; // To track if OTP has been sent

  @override
  void initState() {
    super.initState();
  }

  // Function to send OTP to the phone number
  Future<void> _sendOtp(String phoneNumber) async {
    setState(() {
      _isLoading = true;
      _isOtpSent = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential phoneAuthCredential) async {
        // If auto-retrieval or instant verification is successful
        await _reauthenticateWithPhoneNumber(phoneAuthCredential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Verification failed: ${e.message}"),
          backgroundColor: const Color(0xFFEae6de),
        ));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
          _verificationId = verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('OTP sent to $phoneNumber'),
          backgroundColor: Colors.green,
        ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  // Function to verify OTP and reauthenticate user
  Future<void> _verifyOtpAndReauthenticate(String smsCode) async {
    if (smsCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the OTP'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      final User user = _auth.currentUser!;
      await user.reauthenticateWithCredential(credential);

      // Once verified, proceed with account deletion
      deleteUserAccount();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('OTP verification failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Function to reauthenticate the user with OTP
  Future<void> _reauthenticateWithPhoneNumber(
      PhoneAuthCredential credential) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Re-authenticate the user with the provided credential
        await user.reauthenticateWithCredential(credential);

        // If reauthentication is successful, proceed to delete the user account
        deleteUserAccount();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reauthentication failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Function to delete the user account
  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;

    if (user != null) {
      final userId = user.uid;

      try {
        setState(() {
          _isLoading = true;
        });

        // Step 1: Delete Firestore data
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        // Step 2: Delete authentication profile
        await user.delete();

        // Navigate to sign-in screen after deletion
        Navigator.of(context).pushReplacementNamed('/sign_in');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Function to show confirmation dialog before deletion
  void showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Trigger OTP sending for reauthentication
                _sendOtp(_auth.currentUser!.phoneNumber!);
              },
              child: const Text('Delete'),
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
        title: const Text('Delete Account',
            style: TextStyle(
                color: Color(0xFF003780), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEae6de),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Show loading indicator
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Add image above the button
                  Image.asset(
                    'assets/images/de.png', // Provide the correct path to your image
                    width: 300, // You can adjust the width and height as needed
                    height: 300,
                  ),
                  const SizedBox(
                      height: 20), // Add space between image and button
                  if (!_isOtpSent)
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => showConfirmationDialog(context),
                      child: const Text('Delete My Account'),
                    ),
                  if (_isOtpSent)
                    Column(
                      children: [
                        Pinput(
                          length: 6, // Set the length of the OTP
                          controller: _smsCodeController,
                          pinAnimationType: PinAnimationType.fade,
                          onCompleted: (smsCode) {
                            // When OTP is entered, call this function to verify OTP
                            _verifyOtpAndReauthenticate(smsCode);
                          },
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 50,
                            textStyle: const TextStyle(
                                fontSize: 20, color: Colors.black),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // When button is clicked, verify OTP
                            _verifyOtpAndReauthenticate(
                                _smsCodeController.text.trim());
                          },
                          child: const Text('Verify OTP'),
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: 40,
                  ),
                  const Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Warning:',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        ' Deleting your account will permanently remove all your data from our database, including your personal information, services, and bookings. This action cannot be undone.',
                        style: TextStyle(
                            color: Color(0xFF003780),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
      ),
    );
  }
}
