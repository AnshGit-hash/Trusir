import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/common/menu.dart';
import 'package:trusir/common/otp_screen.dart';

// Custom class to handle responsive dimensions
class ResponsiveDimensions {
  final double screenWidth;
  final double screenHeight;
  final double safeHeight;

  ResponsiveDimensions({
    required this.screenWidth,
    required this.screenHeight,
    required this.safeHeight,
  });

  // Responsive getters for common dimensions
  double get titleSize => screenWidth * 0.06;
  double get subtitleSize => screenWidth * 0.04;
  double get horizontalPadding => screenWidth * 0.05;
  double get verticalPadding => safeHeight * 0.02;

  // Image dimensions - can be adjusted as needed
  double get carouselImageHeight => safeHeight * 0.5;
  double get carouselImageWidth => screenWidth;
  double get flagIconSize => screenWidth * 0.06;
}

class TrusirLoginPage extends StatefulWidget {
  // Allow customization of carousel image size ratio
  final double carouselImageHeightRatio;

  const TrusirLoginPage({
    super.key,
    this.carouselImageHeightRatio = 0.5,
  });

  @override
  TrusirLoginPageState createState() => TrusirLoginPageState();
}

class TrusirLoginPageState extends State<TrusirLoginPage> {
  final TextEditingController _phonecontroller = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String phonenum = '';
  bool _isSendingOTP = false;

  Future<void> storePhoneNo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phonenum);
    print('Phone Number Stored to shared preferences: $phonenum');
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < pageContent.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  final List<Map<String, String>> pageContent = [
    {
      'title': '',
      'subtitle': '',
      'imagePath': 'assets/003.png',
    },
    {
      'title': '',
      'subtitle': '',
      'imagePath': 'assets/004.png',
    },
    {
      'title': 'Trusted Teachers',
      'subtitle': 'Trusted teachers by \nTrusir',
      'imagePath': 'assets/girlimage@4x.png',
    },
    {
      'title': '',
      'subtitle': '',
      'imagePath': 'assets/005.png',
    },
    {
      'title': '',
      'subtitle': '',
      'imagePath': 'assets/002.png',
    },
  ];

  Widget _buildSendOTPButton(ResponsiveDimensions responsive) {
    return Center(
      child: _isSendingOTP
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF48116A)),
            )
          : GestureDetector(
              onTap: () {
                final phone = _phonecontroller.text.trim();
                if (phone.length == 10) {
                  setState(() {
                    _isSendingOTP = true;
                    phonenum = phone;
                  });
                  storePhoneNo();
                  sendOTP(phone);
                } else {
                  showCustomToast(
                      context, 'Enter a valid 10-digit phone number');
                }
              },
              child: Image.asset(
                'assets/send_otp.png',
                width: responsive.screenWidth,
                fit: BoxFit.contain,
              ),
            ),
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(width: 3, color: Colors.grey),
            borderRadius: BorderRadius.circular(35)),
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.grey[200]!; // Color when pressed
                } else if (states.contains(MaterialState.hovered)) {
                  return Colors.grey[200]!; // Color when hovered
                }
                return Colors.grey[200]!; // Default color
              },
            ),
            elevation: MaterialStateProperty.all(0),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            ),
          ),
          onPressed: () => showPopupDialog(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip',
                style: TextStyle(
                  color: Color.fromRGBO(72, 17, 106, 1),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.fast_forward,
                color: Color.from(alpha: 1, red: 0.659, green: 0, blue: 0),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> sendOTP(String phoneNumber) async {
    try {
      setState(() {
        _isSendingOTP = true;
        phonenum = phoneNumber;
      });

      await storePhoneNo();

      // Navigate to OTP screen immediately with loading state
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(
            phonenum: phoneNumber,
            verificationId: '', // Will be updated when code is sent
            isLoading: true, // Show loading state initially
          ),
        ),
      );

      String formattedPhone = '+91$phoneNumber';

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          print("Auto-verified: ${credential.smsCode}");
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Firebase OTP Error: ${e.message}");
          Navigator.pop(context); // Return to login if verification fails
          showCustomToast(context, 'Failed to send OTP: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Replace the loading OTP screen with the actual one
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                phonenum: phoneNumber,
                verificationId: verificationId,
                isLoading: false,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("OTP timeout: $verificationId");
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print("OTP Error: $e");
      Navigator.pop(context); // Return to login if error occurs
      showCustomToast(context, 'Failed to send OTP');
    } finally {
      setState(() {
        _isSendingOTP = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final safeHeight = size.height - padding.top - padding.bottom;

    final responsive = ResponsiveDimensions(
      screenWidth: size.width,
      screenHeight: size.height,
      safeHeight: safeHeight,
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: true, // Adjust the layout when keyboard appears
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Switch between web and mobile layout
            final isWeb = constraints.maxWidth > 900;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: responsive.verticalPadding,
              ),
              child: SingleChildScrollView(
                child: isWeb
                    ? _buildWebLayout(responsive)
                    : _buildMobileLayout(responsive),
              ),
            );
          },
        ),
      ),
    );
  }

  // Web layout: Carousel on the left, Phone input on the right
  Widget _buildWebLayout(ResponsiveDimensions responsive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Carousel
        Expanded(
          flex: 2,
          child: Column(
            children: [
              SizedBox(height: responsive.safeHeight * 0.03),
              _buildCarousel(responsive, true),
              SizedBox(height: responsive.safeHeight * 0.03),
              _buildPageIndicators(responsive, true),
            ],
          ),
        ),
        // Spacing between sections
        // Right side: Phone input
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(responsive, true),
              SizedBox(height: responsive.safeHeight * 0.1),
              _buildPhoneInput(responsive, true),
              SizedBox(height: responsive.safeHeight * 0.04),
              _buildSendOTPButton(responsive),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile layout: Stacked vertical layout
  Widget _buildMobileLayout(ResponsiveDimensions responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(responsive, false),
        SizedBox(height: responsive.safeHeight * 0.03),
        _buildCarousel(responsive, false),
        SizedBox(height: responsive.safeHeight * 0.01),
        _buildPageIndicators(responsive, false),
        SizedBox(height: responsive.safeHeight * 0.03),
        _buildPhoneInput(responsive, false),
        SizedBox(height: responsive.safeHeight * 0.04),
        _buildSendOTPButton(responsive),
      ],
    );
  }

  Widget _buildHeader(ResponsiveDimensions responsive, bool isWeb) {
    return Row(
      mainAxisAlignment:
          isWeb ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [_buildSkipButton()],
    );
  }

  Widget _buildCarousel(ResponsiveDimensions responsive, bool isWeb) {
    return SizedBox(
      height: isWeb ? 600 : 450,
      width: isWeb ? 800 : 700,
      child: PageView.builder(
        physics:
            const BouncingScrollPhysics(), // Standard touch physics for mobile
        controller: _pageController,
        itemCount: pageContent.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final hasText = pageContent[index]['title']!.isNotEmpty ||
              pageContent[index]['subtitle']!.isNotEmpty;

          return isWeb
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        if (_currentPage > 0) {
                          _currentPage--;
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasText) ...[
                          Text(
                            pageContent[index]['title']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isWeb ? 30 : 25,
                              fontWeight: FontWeight.w900,
                              color: HexColor('#6e0096'),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: isWeb ? 16 : 8),
                          Text(
                            pageContent[index]['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isWeb ? 22 : responsive.subtitleSize,
                              fontWeight: FontWeight.bold,
                              color: HexColor('#b617d4'),
                              fontFamily: 'Poppins-semi bold',
                            ),
                          ),
                        ],
                        Expanded(
                          child: Image.asset(
                            pageContent[index]['imagePath']!,
                            width: isWeb ? 500 : responsive.carouselImageWidth,
                            height:
                                isWeb ? 400 : responsive.carouselImageHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        if (_currentPage < pageContent.length - 1) {
                          _currentPage++;
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasText) ...[
                      Text(
                        pageContent[index]['title']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isWeb ? 30 : 25,
                          fontWeight: FontWeight.w900,
                          color: HexColor('#6e0096'),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: isWeb ? 16 : 8),
                      Text(
                        pageContent[index]['subtitle']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isWeb ? 22 : responsive.subtitleSize,
                          fontWeight: FontWeight.bold,
                          color: HexColor('#b617d4'),
                          fontFamily: 'Poppins-semi bold',
                        ),
                      ),
                    ],
                    Expanded(
                      child: Image.asset(
                        pageContent[index]['imagePath']!,
                        width: isWeb ? 500 : responsive.carouselImageWidth,
                        height: isWeb ? 400 : responsive.carouselImageHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildPageIndicators(ResponsiveDimensions responsive, bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageContent.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(
            horizontal: isWeb
                ? responsive.screenWidth * 0.005
                : responsive.screenWidth * 0.01,
          ),
          height: isWeb
              ? responsive.screenWidth * 0.02
              : responsive.screenWidth * 0.03,
          width: isWeb
              ? responsive.screenWidth * 0.02
              : responsive.screenWidth * 0.03,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color.fromRGBO(72, 17, 106, 1)
                : Colors.grey,
            borderRadius: BorderRadius.circular(180),
          ),
        );
      }),
    );
  }

  Widget _buildPhoneInput(ResponsiveDimensions responsive, bool isWeb) {
    return Stack(
      children: [
        // Background shape for the input field
        Container(
          width: double.infinity,
          height: isWeb
              ? responsive.safeHeight * 0.1
              : responsive.safeHeight * 0.08,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(35),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        // Input content
        Container(
          height: isWeb
              ? responsive.safeHeight * 0.1
              : responsive.safeHeight * 0.08,
          padding: EdgeInsets.symmetric(
            horizontal: isWeb
                ? responsive.screenWidth * 0.02
                : responsive.screenWidth * 0.04,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Add this
              children: [
                // Country flag icon
                Center(
                  child: Image.asset(
                    'assets/indianflag.png',
                    width: isWeb
                        ? responsive.flagIconSize * 0.4
                        : responsive.flagIconSize,
                    height: isWeb
                        ? responsive.flagIconSize * 0.4
                        : responsive.flagIconSize,
                  ),
                ),
                SizedBox(
                    width: isWeb
                        ? responsive.screenWidth * 0.01
                        : responsive.screenWidth * 0.02),
                // Country code text
                Center(
                  child: Text(
                    "+91 |",
                    style: TextStyle(
                      fontSize: isWeb
                          ? responsive.screenWidth * 0.015
                          : responsive.screenWidth * 0.04,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(
                    width: isWeb
                        ? responsive.screenWidth * 0.01
                        : responsive.screenWidth * 0.02),
                // Mobile number input field
                Expanded(
                  child: Center(
                    // Add this
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (_,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                        onChanged: (value) {
                          if (value.length == 10) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                        controller: _phonecontroller,
                        textAlignVertical:
                            TextAlignVertical.center, // Modified this
                        style: TextStyle(
                          fontSize: isWeb
                              ? responsive.screenWidth * 0.015
                              : responsive.screenWidth * 0.04,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Mobile Number',
                          hintStyle: TextStyle(
                            fontSize: isWeb
                                ? responsive.screenWidth * 0.015
                                : responsive.screenWidth * 0.04,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          border: InputBorder.none,
                          isDense: true, // Add this
                          contentPadding:
                              const EdgeInsets.only(top: 5), // Add this
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
