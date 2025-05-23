import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/common/image_uploading.dart';
import 'package:trusir/common/test_series.dart';

class Addtestseries extends StatefulWidget {
  final String userID;
  const Addtestseries({super.key, required this.userID});

  @override
  State<Addtestseries> createState() => _AddtestseriesState();
}

class _AddtestseriesState extends State<Addtestseries> {
  final _formKey = GlobalKey<FormState>();
  String? selectedSubject;
  final TextEditingController _testNameController = TextEditingController();
  String? photo;
  String answer = '';
  bool isQuestion = false;
  bool isAnswer = false;
  bool isquestionUploading = false;
  bool isanswerUploading = false;
  String question = '';
  List<String> _courses = [];
  String extension = '';

  Future<void> handleUploadFromCamera() async {
    final String result =
        await ImageUploadUtils.uploadMultipleImagesFromCamera(context);

    if (result != 'null') {
      setState(() {
        if (isQuestion) {
          isquestionUploading = false;
          isQuestion = false;
          if (question == '' || question.isEmpty) {
            question = result;
          } else {
            question = '$question,$result';
          }
        } else if (isAnswer) {
          isanswerUploading = false;
          isAnswer = false;
          if (answer == '' || answer.isEmpty) {
            answer = result;
          } else {
            answer = '$answer,$result';
          }
        } // Save the download URL in the local variable
      });
      showCustomToast(context, 'Image uploaded successfully!');
    } else {
      showCustomToast(context, 'Image upload failed!');
      setState(() {
        if (isQuestion) {
          isquestionUploading = false;
        } else if (isAnswer) {
          isanswerUploading = false;
        }
      });
    }
  }

  Future<void> handleUploadFromGallery() async {
    final String result =
        await ImageUploadUtils.uploadMultipleImagesFromGallery(context);

    if (result != 'null') {
      setState(() {
        if (isQuestion) {
          isquestionUploading = false;
          isQuestion = false;
          if (question == '' || question.isEmpty) {
            question = result;
          } else {
            question = '$question,$result';
          }
        } else if (isAnswer) {
          isanswerUploading = false;
          isAnswer = false;
          if (answer == '' || answer.isEmpty) {
            answer = result;
          } else {
            answer = '$answer,$result';
          }
        } // Save the download URL in the local variable
      });
      showCustomToast(context, 'Images uploaded successfully!');
    } else {
      showCustomToast(context, 'Image upload failed!');
      setState(() {
        if (isQuestion) {
          isquestionUploading = false;
        } else if (isAnswer) {
          isanswerUploading = false;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAllCourses();
  }

  // Function to send data to the API
  Future<void> _sendTestData(String testName, String subject) async {
    // Get the current date and time
    final now = DateTime.now();
    final currentDate = "${now.year}-${now.month}-${now.day}";
    final currentTime = "${now.hour}:${now.minute}";

    final userID = widget.userID;

    // Construct the API payload
    final postData = {
      "userID": userID, // Replace with dynamic user ID if available
      "test_name": testName,
      "question": question,
      "answer": answer,
      "subject": subject,
      "date": currentDate,
      "time": currentTime,
    };
    print("${postData["question"]}  ${postData["answer"]}");

    // Send the POST request
    const apiUrl =
        "$baseUrl/api/store-test-series"; // Replace with your API URL
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(postData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showCustomToast(context, 'Test Uploaded Successfully');
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TestSeriesScreen(
                      userID: widget.userID,
                    )));
        print(postData);
      } else {
        showCustomToast(context, 'Failed to upload test');
      }
    } catch (e) {
      showCustomToast(context, 'Internal Server Error');
    }
  }

  Future<void> fetchAllCourses() async {
    final url = Uri.parse('$baseUrl/get-courses/${widget.userID}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (mounted) {
        setState(() {
          // Use a Set to ensure unique values
          final Set<String> uniqueCourses = {};

          for (var course in data) {
            final subject = course['courseName'] as String;
            final teacherID = course['teacherID'];

            // Filter out courses where teacherID is 'N/A' or null
            if (teacherID != null && teacherID != 'N/A') {
              uniqueCourses.add(subject);
            }
          }

          // Convert sets back to lists
          _courses = uniqueCourses.toList();
        });
      }
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for tight layout
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Test Name Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _testNameController,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    labelText: 'Test Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        width: 1,
                        color: Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        width: 1,
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        width: 1,
                        color: Colors.blue,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a test name';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Subject Dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        width: 1,
                        color: Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        width: 1,
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        width: 1,
                        color: Colors.blue,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: _courses.map((String subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedSubject = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a subject';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Upload Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, bottom: 7),
                    child: isquestionUploading
                        ? const CircularProgressIndicator()
                        : Container(
                            width: 100,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  7.2), // Adjusted for smaller size
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha(50), // Adjusted opacity
                                  offset: const Offset(1, 1), // Scaled offset
                                  blurRadius: 2, // Scaled blur radius
                                ),
                              ],
                            ),
                            child: question.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierColor:
                                            Colors.black.withOpacity(0.3),
                                        builder: (BuildContext context) {
                                          List<String> images =
                                              question.split(',');

                                          return StatefulBuilder(builder:
                                              (context, setStateDialog) {
                                            return Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              insetPadding:
                                                  const EdgeInsets.all(16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      "Uploaded Images",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    GridView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      gridDelegate:
                                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 3,
                                                        crossAxisSpacing: 10,
                                                        mainAxisSpacing: 10,
                                                      ),
                                                      itemCount: images.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Stack(
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Expanded(
                                                                  child: Image
                                                                      .network(
                                                                    images[
                                                                        index],
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                Text(
                                                                  '${_testNameController.text}_question_$index',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize: 8,
                                                                    color: Colors
                                                                        .blue,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                            Positioned(
                                                              top: 0,
                                                              right: 0,
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    images.removeAt(
                                                                        index);
                                                                    question =
                                                                        images.join(
                                                                            ','); // Update URL string
                                                                  });
                                                                  setStateDialog(
                                                                      () {});
                                                                  showCustomToast(
                                                                    context,
                                                                    'Image removed!',
                                                                  );
                                                                },
                                                                child:
                                                                    const CircleAvatar(
                                                                  radius: 12,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  child: Icon(
                                                                    Icons.close,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 16,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            setState(() {
                                                              isQuestion = true;
                                                              isquestionUploading =
                                                                  true;
                                                            });
                                                            handleUploadFromCamera();
                                                          },
                                                          child: const Text(
                                                              "Camera"),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            setState(() {
                                                              isQuestion = true;
                                                              isquestionUploading =
                                                                  true;
                                                            });
                                                            handleUploadFromGallery();
                                                          },
                                                          child: const Text(
                                                              "Gallery"),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      );
                                    },
                                    child: Image.network(
                                      question.split(',').first,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierColor:
                                            Colors.black.withValues(alpha: 0.3),
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding:
                                                const EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 200,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .lightBlue.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          isQuestion = true;
                                                          isquestionUploading =
                                                              true;
                                                        });
                                                        handleUploadFromCamera();
                                                      },
                                                      child: const Text(
                                                        "Camera",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors.black,
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: 200,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .orange.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          isQuestion = true;
                                                          isquestionUploading =
                                                              true;
                                                        });
                                                        handleUploadFromGallery();
                                                      },
                                                      child: const Text(
                                                        "Upload File",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors.black,
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: Icon(
                                            Icons.upload_file_rounded,
                                            size: 23,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Center(
                                          child: Text(
                                            'Upload Questions',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 9, // Scaled font size
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            'Click here',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey,
                                              fontSize: 9,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0, bottom: 7),
                    child: isanswerUploading
                        ? const CircularProgressIndicator()
                        : Container(
                            width: 100,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7.2),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: answer.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierColor:
                                            Colors.black.withOpacity(0.3),
                                        builder: (BuildContext context) {
                                          List<String> images =
                                              answer.split(',');

                                          return StatefulBuilder(builder:
                                              (context, setStateDialog) {
                                            return Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              insetPadding:
                                                  const EdgeInsets.all(16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      "Uploaded Images",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    GridView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      gridDelegate:
                                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 3,
                                                        crossAxisSpacing: 10,
                                                        mainAxisSpacing: 10,
                                                      ),
                                                      itemCount: images.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Stack(
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Expanded(
                                                                  child: Image
                                                                      .network(
                                                                    images[
                                                                        index],
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                Text(
                                                                  '${_testNameController.text}_answer_$index',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize: 8,
                                                                    color: Colors
                                                                        .blue,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                            Positioned(
                                                              top: 0,
                                                              right: 0,
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    images.removeAt(
                                                                        index);
                                                                    answer = images
                                                                        .join(
                                                                            ','); // Update URL string
                                                                  });
                                                                  setStateDialog(
                                                                      () {});
                                                                  showCustomToast(
                                                                    context,
                                                                    'Image removed!',
                                                                  );
                                                                },
                                                                child:
                                                                    const CircleAvatar(
                                                                  radius: 12,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  child: Icon(
                                                                    Icons.close,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 16,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            setState(() {
                                                              isAnswer = true;
                                                              isanswerUploading =
                                                                  true;
                                                            });
                                                            handleUploadFromCamera();
                                                          },
                                                          child: const Text(
                                                              "Camera"),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            setState(() {
                                                              isAnswer = true;
                                                              isanswerUploading =
                                                                  true;
                                                            });
                                                            handleUploadFromGallery();
                                                          },
                                                          child: const Text(
                                                              "Gallery"),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      );
                                    },
                                    child: Image.network(
                                      answer.split(',').first,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierColor:
                                            Colors.black.withValues(alpha: 0.3),
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding:
                                                const EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 200,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .lightBlue.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          isAnswer = true;
                                                          isanswerUploading =
                                                              true;
                                                        });
                                                        handleUploadFromCamera();
                                                      },
                                                      child: const Text(
                                                        "Camera",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors.black,
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: 200,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .orange.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              22),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          isAnswer = true;
                                                          isanswerUploading =
                                                              true;
                                                        });
                                                        handleUploadFromGallery();
                                                      },
                                                      child: const Text(
                                                        "Upload File",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors.black,
                                                            fontFamily:
                                                                'Poppins'),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: Icon(
                                            Icons.upload_file_rounded,
                                            color: Colors.indigo,
                                            size: 23,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Center(
                                          child: Text(
                                            'Upload Answers',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            'Click here',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 9,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  _submitForm();
                },
                child: Image.asset(
                  'assets/create_test.png',
                  width: double.infinity,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_testNameController.text.isEmpty) {
        _testNameController.text = 'No Title';
      }
      if (question.isEmpty) {
        question = 'No Question';
      }
      if (answer.isEmpty) {
        showCustomToast(context, 'Please upload answers');
        return;
      }
      _sendTestData(
        _testNameController.text,
        selectedSubject!,
      );
    }
  }
}
