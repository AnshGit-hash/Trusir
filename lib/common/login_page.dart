import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/menu.dart';
import 'package:http/http.dart' as http;
import 'package:trusir/common/api.dart';
import 'package:trusir/common/otp_screen.dart';

class ResponsiveDimensions {
  final double screenWidth;
  final double screenHeight;
  final double safeHeight;
  final bool isWeb;

  ResponsiveDimensions({
    required this.screenWidth,
    required this.screenHeight,
    required this.safeHeight,
    required this.isWeb,
  });

  // Responsive sizing based on platform
  double get titleSize => isWeb ? screenWidth * 0.03 : screenWidth * 0.06;
  double get subtitleSize => isWeb ? screenWidth * 0.02 : screenWidth * 0.04;
  double get horizontalPadding =>
      isWeb ? screenWidth * 0.1 : screenWidth * 0.05;
  double get verticalPadding => isWeb ? safeHeight * 0.05 : safeHeight * 0.02;
  double get carouselImageHeight => isWeb ? safeHeight * 0.6 : safeHeight * 0.4;
  double get carouselImageWidth => isWeb ? screenWidth * 0.6 : screenWidth;
  double get flagIconSize => isWeb ? screenWidth * 0.03 : screenWidth * 0.06;
  double get inputFieldHeight => isWeb ? safeHeight * 0.08 : safeHeight * 0.07;
  double get buttonHeight => isWeb ? safeHeight * 0.08 : safeHeight * 0.1;
  double get carouselArrowSize => isWeb ? 40 : 30;
  double get indicatorSize => isWeb ? 12 : 8;
  double get indicatorSpacing => isWeb ? 10 : 5;
  EdgeInsets get contentPadding => isWeb
      ? EdgeInsets.symmetric(horizontal: screenWidth * 0.1)
      : EdgeInsets.zero;
}

class TrusirLoginPage extends StatefulWidget {
  const TrusirLoginPage({super.key});

  @override
  TrusirLoginPageState createState() => TrusirLoginPageState();
}

class TrusirLoginPageState extends State<TrusirLoginPage> {
  final TextEditingController _phonecontroller = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String phonenum = '';
  Timer? _carouselTimer;

  Future<void> storePhoneNo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phonenum);
    debugPrint('Phone Number Stored to shared preferences: $phonenum');
  }

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _phonecontroller.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < pageContent.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
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
    return SizedBox(
      height: responsive.buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _handleOTPButtonPress,
        child: Image.asset(
          'assets/send_otp.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _handleOTPButtonPress() {
    setState(() {
      phonenum = _phonecontroller.text;
    });

    if (phonenum.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(phonenum)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid phone number'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (phonenum == '7084696179' ||
        phonenum == '9026154436' ||
        phonenum == '9504072969' ||
        phonenum == '8582040204' ||
        phonenum == '9801458766') {
      storePhoneNo();
      _navigateToOTPScreen();
    } else {
      sendOTP(phonenum);
    }
  }

  void _navigateToOTPScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(phonenum: phonenum),
      ),
    );
  }

  Widget _buildSkipButton(ResponsiveDimensions responsive) {
    return Container(
      height: responsive.isWeb ? 45 : 40,
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(width: 3, color: Colors.grey),
        borderRadius: BorderRadius.circular(35),
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.grey[200]),
          elevation: MaterialStateProperty.all(0),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: responsive.isWeb ? 20 : 6,
              vertical: 0,
            ),
          ),
        ),
        onPressed: () => showPopupDialog(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: const Color.fromRGBO(72, 17, 106, 1),
                fontSize: responsive.isWeb ? 18 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.fast_forward,
              color: const Color.fromRGBO(168, 0, 0, 1),
              size: responsive.isWeb ? 22 : 19,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendOTP(String phoneNumber) async {
    final url = Uri.parse('$otpapi/SMS/+91$phoneNumber/AUTOGEN3/TRUSIR_OTP');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        debugPrint('OTP sent successfully: ${response.body}');
        await storePhoneNo();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP Sent Successfully'),
            duration: Duration(seconds: 1),
          ),
        );
        _navigateToOTPScreen();
      } else {
        debugPrint('Failed to send OTP: ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please check your connection.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final safeHeight = size.height - padding.top - padding.bottom;
    final isWeb = size.width > 900;

    final responsive = ResponsiveDimensions(
      screenWidth: size.width,
      screenHeight: size.height,
      safeHeight: safeHeight,
      isWeb: isWeb,
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: responsive.contentPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 1200 : double.infinity,
              ),
              child: SingleChildScrollView(
                child: isWeb
                    ? _buildWebLayout(responsive)
                    : _buildMobileLayout(responsive),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(ResponsiveDimensions responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: responsive.verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Carousel Section
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildCarousel(responsive),
                const SizedBox(height: 20),
                _buildPageIndicators(responsive),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Login Form Section
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildSkipButton(responsive),
                ),
                const SizedBox(height: 40),
                _buildPhoneInput(responsive),
                const SizedBox(height: 30),
                _buildSendOTPButton(responsive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ResponsiveDimensions responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: responsive.verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _buildSkipButton(responsive),
          ),
          const SizedBox(height: 20),
          _buildCarousel(responsive),
          const SizedBox(height: 10),
          _buildPageIndicators(responsive),
          const SizedBox(height: 30),
          _buildPhoneInput(responsive),
          const SizedBox(height: 30),
          _buildSendOTPButton(responsive),
        ],
      ),
    );
  }

  Widget _buildCarousel(ResponsiveDimensions responsive) {
    return SizedBox(
      height: responsive.carouselImageHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: _pageController,
            itemCount: pageContent.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final item = pageContent[index];
              final hasText =
                  item['title']!.isNotEmpty || item['subtitle']!.isNotEmpty;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasText) ...[
                    Text(
                      item['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: responsive.titleSize,
                        fontWeight: FontWeight.w900,
                        color: HexColor('#6e0096'),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['subtitle']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: responsive.subtitleSize,
                        fontWeight: FontWeight.bold,
                        color: HexColor('#b617d4'),
                        fontFamily: 'Poppins-semi bold',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Expanded(
                    child: Image.asset(
                      item['imagePath']!,
                      width: responsive.carouselImageWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              );
            },
          ),
          if (responsive.isWeb) ...[
            Positioned(
              left: 0,
              child: IconButton(
                iconSize: responsive.carouselArrowSize,
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _goToPreviousPage,
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                iconSize: responsive.carouselArrowSize,
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _goToNextPage,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPage < pageContent.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildPageIndicators(ResponsiveDimensions responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageContent.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: responsive.indicatorSpacing),
          height: responsive.indicatorSize,
          width: responsive.indicatorSize,
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

  Widget _buildPhoneInput(ResponsiveDimensions responsive) {
    return Container(
      height: responsive.inputFieldHeight,
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
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isWeb ? 30 : 20,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/indianflag.png',
            width: responsive.flagIconSize,
            height: responsive.flagIconSize,
          ),
          const SizedBox(width: 10),
          Text(
            "+91 |",
            style: TextStyle(
              fontSize: responsive.isWeb ? 18 : 16,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _phonecontroller,
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
              style: TextStyle(
                fontSize: responsive.isWeb ? 18 : 16,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: TextStyle(
                  fontSize: responsive.isWeb ? 18 : 16,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
