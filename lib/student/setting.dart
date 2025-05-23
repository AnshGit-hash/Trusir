import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/contactus.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/common/parents_doubts.dart';
import 'package:trusir/common/about_us.dart';
import 'package:trusir/common/refund_policy.dart';
import 'package:trusir/student/main_screen.dart';
import 'package:trusir/student/student_tnc.dart';
import 'package:trusir/student/your_doubt.dart';

class SettingsScreen extends StatefulWidget {
  final bool checking;
  final String checkTitle;
  const SettingsScreen(
      {super.key, required this.checking, required this.checkTitle});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void dispose() {
    // Reset status bar to default when leaving the page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  String userID = '';

  bool isWeb = false;

  Future<void> fetchuserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userID')!;
  }

  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600;

    // Define the settings items
    final List<Map<String, dynamic>> settingsItems = [
      {
        'image': 'assets/pensp@3x.png',
        'color': Colors.indigo.shade200,
        'title': 'Your Doubts',
        'route': const YourDoubtPage(),
      },
      {
        'image': 'assets/men@4x.png',
        'color': Colors.blue.shade200,
        'title': 'Parents Doubts',
        'route': const ParentsDoubtsPage(),
      },
      {
        'image': 'assets/aboutus.png',
        'color': Colors.purple.shade100,
        'title': 'About Us',
        'route': const AboutUsPage(),
      },
      {
        'image': 'assets/phone@3x.png',
        'color': Colors.indigo.shade200,
        'title': 'Contact Us',
        'route': const Contactus(),
      },
      {
        'image': 'assets/tnc.png',
        'color': Colors.blue.shade200,
        'title': 'Refund Policy',
        'route': const RefundPolicyPage(),
      },
      {
        'image': 'assets/tnc.png',
        'color': Colors.pink.shade200,
        'title': 'Terms & Conditions',
        'route': const TrusirTermsPage(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 1.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(index: 2),
                    ),
                  );
                },
                child: Image.asset('assets/back_button.png', height: 50),
              ),
              const SizedBox(width: 20),
              const Text(
                'Setting',
                style: TextStyle(
                  color: Color(0xFF48116A),
                  fontSize: 25,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 40 : 10,
            vertical: isWeb ? 20 : 20,
          ),
          child: isWeb
              ? _buildWebLayout(context, settingsItems)
              : _buildMobileLayout(context, settingsItems),
        ),
      ),
    );
  }

  Widget _buildWebLayout(
      BuildContext context, List<Map<String, dynamic>> settingsItems) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < settingsItems.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _settingscard(
                    context,
                    90, // Increased container size
                    50, // Increased image size
                    60, // Increased height
                    450,
                    settingsItems[i]['image'],
                    settingsItems[i]['color'],
                    () => widget.checking
                        ? () {
                            showCustomToast(context, widget.checkTitle);
                          }
                        : Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => settingsItems[i]['route'],
                            ),
                          ),
                    settingsItems[i]['title'],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (int i = 1; i < settingsItems.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _settingscard(
                    context,
                    90,
                    50,
                    60,
                    450,
                    settingsItems[i]['image'],
                    settingsItems[i]['color'],
                    () => widget.checking
                        ? () {
                            showCustomToast(context, widget.checkTitle);
                          }
                        : Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => settingsItems[i]['route'],
                            ),
                          ),
                    settingsItems[i]['title'],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, List<Map<String, dynamic>> settingsItems) {
    return Column(
      children: [
        for (var item in settingsItems) ...[
          _settingscard(
            context,
            50,
            36,
            53,
            306,
            item['image'],
            item['color'],
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => item['route'],
              ),
            ),
            item['title'],
          ),
          const SizedBox(height: 15),
        ],
      ],
    );
  }

  Widget _settingscard(
    BuildContext context,
    double containerSize,
    double imageSize,
    double newContainerheight,
    double newcontainerwidth,
    String image,
    Color color,
    VoidCallback onTap,
    String title,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 6,
              ),
            ], // Slightly increased border radius
          ),
          child: Center(
            child: SizedBox(
              width: imageSize,
              height: imageSize,
              child: Image.asset(
                image,
                fit: BoxFit.contain, // Changed to contain for better scaling
              ),
            ),
          ),
        ),
        SizedBox(width: isWeb ? 50 : 10),
        Flexible(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: newContainerheight,
              width: newcontainerwidth,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, top: 10, bottom: 10, right: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              isWeb ? 18 : 16, // Increased font size for web
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 15),
                        child: Icon(Icons.arrow_forward_ios_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
