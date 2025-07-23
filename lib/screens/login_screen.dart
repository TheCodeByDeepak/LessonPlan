import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/lesson_planner_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  String verificationId = '';
  bool otpSent = false;
  bool isLoading = false;

  void sendOtp() async {
    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${phoneController.text.trim()}',
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        await saveUserAndNavigate();
      },
      verificationFailed: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
        setState(() => isLoading = false);
      },
      codeSent: (verId, _) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (verId) {
        verificationId = verId;
      },
    );
  }

  void verifyOtp() async {
    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
          credential);
      if (userCred.user != null) {
        await saveUserAndNavigate();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> saveUserAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(
          user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'phone': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LessonPlannerHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo or Name
              Image.asset('assets/logo.png', height: 120),
              // Replace with your logo
              const SizedBox(height: 16),
              Text(
                "LESSON PLAN",
                style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800]),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        otpSent ? 'Enter OTP' : 'Enter Phone Number',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      if (!otpSent) ...[
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                            prefixText: '+91 ',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            helperText: 'We will send an OTP to this number',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                                : const Text(
                                'Send OTP', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ] else
                        ...[
                          TextFormField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'OTP',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                                  : const Text(
                                  'Verify OTP', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                otpSent = false;
                                otpController.clear();
                              });
                            },
                            child: const Text('Change phone number',
                                style: TextStyle(color: Colors.blue)),
                          ),
                        ]
                    ],
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