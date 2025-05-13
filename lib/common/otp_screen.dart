import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/common/enquiry.dart';
import 'package:trusir/common/api.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trusir/common/login_splash_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phonenum;
  final String verificationId; // Added verificationId parameter
  const OTPScreen({
    super.key,
    required this.phonenum,
    required this.verificationId,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  bool newuser = false;
  bool isVerifying = false;
  bool _isButtonEnabled = false;
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _isButtonEnabled = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>?> fetchUserData(String phoneNumber) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final url = Uri.parse('$baseUrl/api/login/$phoneNumber');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('new_user')) {
          final bool isNewUser = responseData['new_user'];
          await prefs.setBool('new_user', isNewUser);
          setState(() {
            newuser = isNewUser;
          });

          if (!isNewUser) {
            await prefs.setString('userID', responseData['uerID']);
            await prefs.setString('role', responseData['role']);
            await prefs.setString('token', responseData['token']);
          }
          return responseData;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> verifyOTP() async {
    String otp = otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(otp)) {
      showCustomToast(context, 'Enter a valid 6-digit OTP');
      return;
    }

    setState(() => isVerifying = true);

    try {
      // Create PhoneAuthCredential with the verification ID and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      // Sign in with the credential
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // On successful verification
      if (userCredential.user != null) {
        await fetchUserData(widget.phonenum);
        showVerificationDialog(context);
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase OTP Error: ${e.message}");
      showCustomToast(context, 'Invalid OTP. Please try again.');
    } catch (e) {
      print("Error verifying OTP: $e");
      showCustomToast(context, 'An error occurred. Please try again.');
    } finally {
      setState(() => isVerifying = false);
    }
  }

  Future<void> resendOTP() async {
    if (!_isButtonEnabled) {
      showCustomToast(context, 'Please wait before resending');
      return;
    }

    try {
      setState(() {
        _isButtonEnabled = false;
        _secondsRemaining = 30;
        startTimer();
      });

      // Re-send OTP using Firebase
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${widget.phonenum}',
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          showCustomToast(context, 'Failed to resend OTP: ${e.message}');
        },
        codeSent: (verificationId, resendToken) {
          // Update verificationId if needed
          print('OTP resent successfully');
          showCustomToast(context, 'OTP resent successfully');
        },
        codeAutoRetrievalTimeout: (verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error resending OTP: $e');
      showCustomToast(context, 'Failed to resend OTP');
    }
  }

  void showVerificationDialog(BuildContext context) {
    showDialog(
      barrierColor: Colors.grey,
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/check.png', height: 100, width: 100),
              const SizedBox(height: 16),
              Text(
                'Your OTP has been verified!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.purple.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );

    Timer(const Duration(seconds: 2), () {
      Navigator.pop(context);
      if (newuser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EnquiryPage()),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginSplashScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 0.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  'assets/back_button.png',
                  height: isWeb ? 60 : 50,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: isWeb ? 90 : 70,
      ),
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 100 : 24.0,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isWeb ? 45 : 35,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF48116A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the verification code \nwe just sent on your phone number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isWeb ? 18 : 16,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 44),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      height: isWeb ? 80 : 55,
                      width: isWeb ? 80 : 55,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color.fromARGB(255, 177, 177, 177),
                          width: 1.5,
                        ),
                      ),
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (RawKeyEvent event) {
                          if (event
                                  .isKeyPressed(LogicalKeyboardKey.backspace) &&
                              otpControllers[index].text.isEmpty &&
                              index > 0) {
                            FocusScope.of(context)
                                .requestFocus(focusNodes[index - 1]);
                            otpControllers[index].clear();
                          }
                        },
                        child: TextFormField(
                          controller: otpControllers[index],
                          focusNode: focusNodes[index],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                                left: 12, right: 10, top: isWeb ? 20 : 8),
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isWeb ? 30 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              FocusScope.of(context)
                                  .requestFocus(focusNodes[index + 1]);
                            } else if (value.isEmpty && index > 0) {
                              FocusScope.of(context)
                                  .requestFocus(focusNodes[index - 1]);
                            }

                            bool allFilled = otpControllers.every(
                                (controller) => controller.text.isNotEmpty);
                            if (allFilled) {
                              FocusScope.of(context).unfocus();
                              verifyOTP();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                TextButton(
                  onPressed: _isButtonEnabled ? resendOTP : null,
                  child: Text(
                    _isButtonEnabled ? 'Resend OTP' : '$_secondsRemaining',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isWeb ? 18 : 16,
                      color: _isButtonEnabled
                          ? const Color(0xFF48116A)
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 70),
                Center(
                  child: isVerifying
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: verifyOTP,
                          child: Image.asset(
                            height: isWeb ? 150 : null,
                            'assets/verify.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
