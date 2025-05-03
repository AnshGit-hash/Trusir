import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/file_downloader.dart';

class StudentProgressPage extends StatefulWidget {
  final String userID;
  const StudentProgressPage({super.key, required this.userID});

  @override
  State<StudentProgressPage> createState() => _StudentProgressPageState();
}

class _StudentProgressPageState extends State<StudentProgressPage> {
  List<dynamic> _loadedReports = [];
  bool reportempty = true;
  Map<String, String> downloadedFiles = {};
  int page = 1;

  final List<Color> containerColors = [
    Colors.lightBlue.shade50,
    Colors.lightGreen.shade50,
    Colors.amber.shade50,
    Colors.pink.shade50,
    Colors.lime.shade50,
    Colors.orange.shade50,
    Colors.teal.shade50,
  ];

  final List<List<Color>> circleColors = [
    [
      Colors.lightBlue.shade200,
      Colors.lightBlue.shade200,
    ],
    [
      Colors.lightGreen.shade200,
      Colors.lightGreen.shade200,
    ],
    [
      Colors.amber.shade200,
      Colors.amber.shade200,
    ],
    [
      Colors.pink.shade200,
      Colors.pink.shade200,
    ],
    [
      Colors.lime.shade200,
      Colors.lime.shade200,
    ],
    [
      Colors.orange.shade200,
      Colors.orange.shade200,
    ],
    [
      Colors.teal.shade200,
      Colors.teal.shade200,
    ],
  ];

  // Add this method to get colors based on index
  Color getContainerColor(int index) {
    return containerColors[index % containerColors.length];
  }

  List<Color> getCircleColors(int index) {
    return circleColors[index % circleColors.length];
  }

  @override
  void initState() {
    super.initState();
    _loadedReports = [];
    reportempty = false;
    _loadInitialReports();
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
    return formattedDate;
  }

  String formatTime(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedTime = DateFormat('hh:mm a').format(dateTime);
    return formattedTime; // Example: 11:40 PM
  }

  void onDownloadComplete(String reporturl, String newPath) {
    setState(() {
      reporturl = newPath;
    });
  }

  Future<List<dynamic>> fetchProgressReports({int page = 1}) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/progress-report/${widget.userID}?page=$page&data_per_page=10'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to load progress reports');
    }
  }

  void _loadMoreReports() async {
    page++;
    try {
      List<dynamic> newReports = await fetchProgressReports(page: page);
      if (newReports.isEmpty) {
        setState(() {
          reportempty = true; // No more data available
        });
      } else {
        setState(() {
          _loadedReports.addAll(newReports);
        });
      }
    } catch (e) {
      print('Error loading more reports: $e');
    }
  }

  void _loadInitialReports() async {
    try {
      List<dynamic> initialReports = await fetchProgressReports();
      setState(() {
        _loadedReports = initialReports;
        reportempty = initialReports.isEmpty;
      });
    } catch (e) {
      print('Error loading initial reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image.asset('assets/back_button.png', height: 50)),
            const SizedBox(width: 20),
            const Text(
              'Progress Report',
              style: TextStyle(
                color: Color(0xFF48116A),
                fontSize: 25,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildBackButton(context),
            _buildCurrentMonthCard(),
            const SizedBox(height: 20),
            _buildPreviousMonthsReports(),
            const SizedBox(height: 20),
            Column(
              children: _loadedReports.isEmpty
                  ? [
                      const Center(child: Text('No Reports Available')),
                    ]
                  : _loadedReports.map((report) {
                      return _buildPreviousMonthCard(
                        subject: report['subject'],
                        date: formatDate(report['created_at']),
                        time: formatTime(report['created_at']),
                        total: report['total_marks'],
                        marks: report['marks'],
                        reportUrl: report['report'],
                        cardColors: 'color',
                        index: _loadedReports.indexOf(report),
                      );
                    }).toList(),
            ),
            const SizedBox(height: 20),
            if (_loadedReports.isNotEmpty)
              reportempty
                  ? const Center(
                      child: Text(
                        'No more reports',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                  : TextButton(
                      onPressed: _loadMoreReports,
                      child: const Text('Load More...'),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: 1.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [],
      ),
    );
  }

  Widget _buildCurrentMonthCard() {
    DateTime now = DateTime.now();
    DateTime firstOfMonth = DateTime(now.year, now.month, 1);
    String formattedStart = DateFormat('d MMM yyyy').format(firstOfMonth);
    return Padding(
      padding: const EdgeInsets.only(
        top: 5.0,
        right: 18,
        left: 18,
      ),
      child: Container(
        width: 386,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF48116A),
              Color(0xFFC22054),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC22054).withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(-5, 5),
            ),
            BoxShadow(
              color: const Color(0xFF48116A).withValues(alpha: 0.5),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 10.0, right: 10, bottom: 10, top: 0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Month',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Poppins",
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$formattedStart - Today',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10.0),
                  child: Image.asset(
                    'assets/listaim@3x.png',
                    width: 100,
                    height: 95,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousMonthsReports() {
    return const Padding(
      padding: EdgeInsets.only(top: 10.0),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          'Previous months Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPreviousMonthCard({
    required String subject,
    required String date,
    required String time,
    required String marks,
    required String total,
    required String reportUrl,
    required String cardColors,
    required int index,
  }) {
    String filename = '${subject}_report_$date.jpg';
    List<Color> currentCircleColors = getCircleColors(index);
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18, top: 0, bottom: 10),
      child: Container(
        width: 386,
        height: 136,
        decoration: BoxDecoration(
          color: getContainerColor(index),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -35,
              child: Image.asset(
                color: currentCircleColors[0],
                'assets/circleleft.png',
                width: 160,
                height: 160,
              ),
            ),
            Positioned(
              bottom: -42,
              right: -40,
              child: Image.asset(
                color: currentCircleColors[0],
                'assets/circleright.png',
                width: 160,
                height: 160,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Marks Obtained: $marks/$total',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Date: $date',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 10, right: 10, bottom: 10.0),
                child: Container(
                  height: 48,
                  width: 357,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: () {
                      FileDownloader.openFile(context, filename, reportUrl);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Report',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new,
                          color: Colors.black,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
