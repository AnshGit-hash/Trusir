import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:intl/intl.dart';

class Notice {
  final String noticetitle;
  final String date;
  final String notice;

  Notice({
    required this.noticetitle,
    required this.notice,
    required this.date,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      noticetitle: json['title'],
      notice: json['description'],
      date: json['posted_on'],
    );
  }
}

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<Notice> notices = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMore = true;
  final apiBase = '$baseUrl/api/my-notice';

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

  Future<void> fetchNotices({int page = 1}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    final url = '$apiBase/$userID?page=$page&data_per_page=10';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        if (page == 1) {
          notices = data.map((json) => Notice.fromJson(json)).toList();
        } else {
          notices.addAll(data.map((json) => Notice.fromJson(json)));
        }

        isLoading = false;
        isLoadingMore = false;

        if (data.isEmpty) {
          hasMore = false;
        }
      });
    } else {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      throw Exception('Failed to load notices');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

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

  final List<Color> cardColors = [
    Colors.blue.shade100,
    Colors.yellow.shade100,
    Colors.pink.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset(
                    'assets/back_button.png',
                    height: constraints.maxWidth > 600 ? 50 : 50,
                  ),
                ),
                SizedBox(width: constraints.maxWidth > 600 ? 20 : 20),
                Text(
                  'Notice',
                  style: TextStyle(
                    color: const Color(0xFF48116A),
                    fontSize: constraints.maxWidth > 600 ? 25 : 25,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        ),
        toolbarHeight: 70,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : notices.isEmpty
              ? const Center(
                  child: Text(
                    "No Notices Available",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth > 1200
                                ? 1200
                                : constraints.maxWidth > 600
                                    ? 800
                                    : constraints.maxWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth > 600 ? 20 : 10,
                              vertical: 15,
                            ),
                            child: Column(
                              children: [
                                ...notices.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Notice notice = entry.value;

                                  // Cycle through colors using the modulus operator
                                  Color cardColor =
                                      cardColors[index % cardColors.length];

                                  return Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 7,
                                          top: 10,
                                          right: 7,
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 386,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: cardColor,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 55,
                                                    top: 13,
                                                    bottom: 10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      notice.noticetitle,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      'Posted on : ${formatDate(notice.date)} ${formatTime(notice.date)}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color.fromARGB(
                                                            255, 133, 133, 133),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      notice.notice,
                                                      style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 13,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 15,
                                              left: 10,
                                              child: Image.asset(
                                                'assets/bell.png',
                                                width: 30,
                                                height: 30,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                hasMore
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20),
                                        child: isLoadingMore
                                            ? const CircularProgressIndicator()
                                            : TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    isLoadingMore = true;
                                                    currentPage++;
                                                  });
                                                  fetchNotices(
                                                      page: currentPage);
                                                },
                                                child:
                                                    const Text('Load More...'),
                                              ),
                                      )
                                    : const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 20),
                                        child: Text('No more Notices'),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
