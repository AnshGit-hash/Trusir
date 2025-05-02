import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/teacher/teachers_registeration.dart';
import 'package:url_launcher/url_launcher.dart';

class Teacherhomepage extends StatefulWidget {
  final bool enableReg;
  const Teacherhomepage({super.key, required this.enableReg});

  @override
  State<Teacherhomepage> createState() => _TeacherhomepageState();
}

class _TeacherhomepageState extends State<Teacherhomepage> {
  String? name;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await fetchProfileData();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    setState(() => _isLoading = false);
  }

  Future<void> fetchProfileData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        name = prefs.getString('name');
      });
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
      setState(() => name = null);
    }
  }

  Future<void> openDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch dialer');
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber, String message) async {
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isWeb = mediaQuery.size.width > 600;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: isWeb ? 50 : 16,
              right: isWeb ? 30 : 16,
              top: isWeb
                  ? 16
                  : widget.enableReg
                      ? 40
                      : 16,
              bottom: widget.enableReg ? (isWeb ? 100 : 80) : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: mediaQuery.size.height,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AppTitle(),
                  SizedBox(height: isWeb ? 25 : 16),
                  _WelcomeSection(name: name, enableReg: widget.enableReg),
                  const SizedBox(height: 10),
                  const _AppDescription(),
                  const SizedBox(height: 24),
                  _ServicesCarousel(isWeb: isWeb),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Our Services'),
                  const SizedBox(height: 20),
                  _ServicesImage(mediaQuery: mediaQuery),
                  if (!widget.enableReg) ...[
                    const _BiharAvailabilityText(),
                    const SizedBox(height: 10),
                    const _BiharMapImage(),
                    const SizedBox(height: 30),
                  ],
                  const _SectionTitle(title: 'Explore City'),
                  const SizedBox(height: 15),
                  const _CityButtons(),
                  if (!widget.enableReg) ...[
                    const SizedBox(height: 30),
                    const _BiharMapChart(),
                    const SizedBox(height: 30),
                  ],
                  const _SectionTitle(title: 'Explore our offerings'),
                  const SizedBox(height: 15),
                  const _ClassButtons(),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'Explore Boards'),
                  const SizedBox(height: 15),
                  const _BoardButtons(),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'Explore Subjects'),
                  const SizedBox(height: 15),
                  const _SubjectButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Fixed Registration Button
          if (widget.enableReg)
            Positioned(
              left: 0,
              right: 0,
              bottom: 5,
              child: _RegistrationButton(isWeb: isWeb),
            ),

          // Floating Action Buttons
          if (!isPortrait || isWeb) ...[
            Positioned(
              right: 13,
              top: mediaQuery.size.height * 0.4,
              child: _WhatsAppButton(isWeb: isWeb),
            ),
            Positioned(
              right: 13,
              top: (isWeb ? 0.55 : 0.48) * mediaQuery.size.height,
              child: _CallButton(isWeb: isWeb),
            ),
          ],
        ],
      ),
      floatingActionButton: isPortrait && !isWeb
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WhatsAppButton(isWeb: isWeb),
                const SizedBox(height: 16),
                _CallButton(isWeb: isWeb),
              ],
            )
          : null,
    );
  }
}

// Extracted widget classes for better organization
class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Trusir.com',
          style: TextStyle(
            color: Color(0xFF48116A),
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final String? name;
  final bool enableReg;

  const _WelcomeSection({required this.name, required this.enableReg});

  @override
  Widget build(BuildContext context) {
    return enableReg
        ? const Text(
            'Welcome To Trusir',
            style: TextStyle(
              fontSize: 35,
              height: 1.0,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          )
        : Text(
            'Hello, ${name ?? 'User'}',
            style: const TextStyle(
              fontSize: 30,
              height: 1.0,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          );
  }
}

class _AppDescription extends StatelessWidget {
  const _AppDescription();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.black, thickness: 3, endIndent: 230),
        SizedBox(height: 10),
        Text(
          'Trusir is a registered and trusted Indian company that offers Home to Home tuition service. We have a clear vision of helping male and female teaching service.',
          style: TextStyle(
            fontSize: 20,
            height: 1.6,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Color(0xFF001241),
          ),
        ),
      ],
    );
  }
}

class _ServicesCarousel extends StatelessWidget {
  final bool isWeb;

  const _ServicesCarousel({required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isWeb ? 350 : 300,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Image.asset(
          'assets/teacher_homepage_scroll.png',
          height: isWeb ? 350 : 300,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isWeb ? 28 : 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF00081D),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ServicesImage extends StatelessWidget {
  final MediaQueryData mediaQuery;

  const _ServicesImage({required this.mediaQuery});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/teacher_homepage.png',
      width: mediaQuery.size.width,
      fit: BoxFit.fitWidth,
    );
  }
}

class _BiharAvailabilityText extends StatelessWidget {
  const _BiharAvailabilityText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'We are Available in Bihar',
      style: TextStyle(
        fontSize: 20,
        height: 1.6,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
    );
  }
}

class _BiharMapImage extends StatelessWidget {
  const _BiharMapImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/homepage_image.jpg');
  }
}

class _CityButtons extends StatelessWidget {
  const _CityButtons();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 5,
      runSpacing: 6,
      children: [
        _PillButton(text: 'Motihari'),
      ],
    );
  }
}

class _BiharMapChart extends StatelessWidget {
  const _BiharMapChart();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/bihar_map_chart.png');
  }
}

class _ClassButtons extends StatelessWidget {
  const _ClassButtons();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 6,
      children: [
        'Nursery',
        'LKG',
        'UKG',
        'Class 1',
        'Class 2',
        'Class 3',
        'Class 4',
        'Class 5',
        'Class 6',
        'Class 7',
        'Class 8',
        'Class 9',
        'Class 10',
      ].map((subject) => _PillButton(text: subject)).toList(),
    );
  }
}

class _BoardButtons extends StatelessWidget {
  const _BoardButtons();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 6,
      children: [
        'Bihar School Examination Board',
        'Central Board of Secondary Education',
        'Indian Certificate of Secondary Education',
      ].map((subject) => _PillButton(text: subject)).toList(),
    );
  }
}

class _SubjectButtons extends StatelessWidget {
  const _SubjectButtons();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 6,
      children: [
        'Hindi',
        'English',
        'Maths',
        'Science: Physics, Chemistry, Biology',
        'Social Science: History, Geography, Political Science, Economics'
      ].map((subject) => _PillButton(text: subject)).toList(),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String text;

  const _PillButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.black,
        ),
      ),
    );
  }
}

class _RegistrationButton extends StatelessWidget {
  final bool isWeb;

  const _RegistrationButton({required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TeacherRegistrationPage(),
            ),
          );
        },
        child: Image.asset(
          'assets/registeration.png',
          width: isWeb ? 380 : 280,
          height: isWeb ? 80 : 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  final bool isWeb;

  const _WhatsAppButton({required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isWeb ? 80 : 50,
      width: isWeb ? 80 : 50,
      child: FloatingActionButton(
        heroTag: 'whatsappButton',
        onPressed: () {
          final state =
              context.findAncestorStateOfType<_TeacherhomepageState>();
          state?._launchWhatsApp('918582040204', 'Hello');
        },
        child: Image.asset('assets/whatsapp@3x.png'),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final bool isWeb;

  const _CallButton({required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isWeb ? 80 : 50,
      width: isWeb ? 80 : 50,
      child: FloatingActionButton(
        heroTag: 'callButton',
        onPressed: () {
          final state =
              context.findAncestorStateOfType<_TeacherhomepageState>();
          state?.openDialer('8582040204');
        },
        child: Image.asset('assets/call.png'),
      ),
    );
  }
}
