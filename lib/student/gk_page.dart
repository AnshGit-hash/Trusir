import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/file_downloader.dart';

// New DetailPage to show GK details
class GKDetailPage extends StatelessWidget {
  final GK gk;

  const GKDetailPage({super.key, required this.gk});

  @override
  Widget build(BuildContext context) {
    String formatDate(String dateString) {
      DateTime dateTime = DateTime.parse(dateString);
      String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
      return formattedDate;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/back_button.png', height: 50),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          gk.title,
          style: const TextStyle(
            color: Color(0xFF48116A),
            fontSize: 25,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    FileDownloader.openFile(
                        context, 'GK_${gk.title}', gk.image);
                  },
                  child: Image.network(
                    gk.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image,
                          size: 200, color: Colors.grey);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Title: ${gk.title}',
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Course: ${gk.course}',
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'Posted on: ${formatDate(gk.createdAt)}',
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    color: Colors.grey,
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

class GKPage extends StatefulWidget {
  const GKPage({super.key});

  @override
  State<GKPage> createState() => _GKPageState();
}

class _GKPageState extends State<GKPage> {
  List<GK> gkList = [];
  int page = 1;
  bool isLoading = false;
  bool hasMoreData = true;
  bool initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    fetchGks();
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

  Future<void> fetchGks() async {
    if (!hasMoreData || isLoading) return; // Prevent unnecessary calls

    setState(() {
      isLoading = true; // Show loading indicator while fetching data
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userID = prefs.getString('userID');

      final response = await http
          .get(Uri.parse(
              '$baseUrl/tecaher-gks/$userID?page=$page&data_per_page=10'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          if (data.isEmpty) {
            hasMoreData = false; // No more data available
          } else {
            gkList.addAll(data.map((json) => GK.fromJson(json)).toList());
            page++; // Increment page for next fetch
          }
        });
      } else {
        throw Exception('Failed to load GKs');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading indicator
        initialLoadComplete = true; // Mark the initial load as complete
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Row(
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/back_button.png', height: 50)),
              const SizedBox(width: 20),
              const Text(
                'GK',
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: gkList.isEmpty
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  gkList.isEmpty && !isLoading && initialLoadComplete
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "No GK's available",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SingleChildScrollView(
                              child: SizedBox(
                                height: (gkList.length * 130.0).clamp(0,
                                    MediaQuery.of(context).size.height * 0.65),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(10.0),
                                  itemCount: gkList.length,
                                  itemBuilder: (context, index) {
                                    final gk = gkList[index];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GKDetailPage(gk: gk),
                                              ),
                                            );
                                          },
                                          child: Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Image.network(
                                                      gk.image,
                                                      width: 75,
                                                      height: 75,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                            size: 50);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10.0),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const SizedBox(
                                                            height: 10),
                                                        Text(
                                                          gk.title,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            fontFamily:
                                                                "Poppins",
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          'Description: ${gk.course}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontFamily:
                                                                "Poppins",
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 5),
                                                        Text(
                                                          'Posted on: ${gk.createdAt}',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "Poppins",
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 10),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (isLoading)
                              const CircularProgressIndicator()
                            else if (!hasMoreData && gkList.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'No more GKs',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            else if (gkList.isNotEmpty)
                              TextButton(
                                onPressed: fetchGks,
                                child: const Text('Load More'),
                              ),
                          ],
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GK {
  final int id;
  final String title;
  final String course;
  final String image;
  final String createdAt;

  GK({
    required this.id,
    required this.title,
    required this.course,
    required this.image,
    required this.createdAt,
  });

  factory GK.fromJson(Map<String, dynamic> json) {
    return GK(
      id: json['id'],
      title: json['title'],
      course: json['description'],
      image: json['image'],
      createdAt: json['created_at'],
    );
  }
}
