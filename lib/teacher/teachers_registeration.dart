import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/image_uploading.dart';
import 'package:trusir/common/login_page.dart';
import 'package:trusir/common/otp_screen.dart';
import 'package:trusir/common/registration_splash_screen.dart';
import 'package:trusir/teacher/teacher_tnc.dart';

import '../common/custom_toast.dart';

class TeacherRegistrationData {
  String? teacherName;
  String? fathersName;
  String? mothersName;
  String? gender;
  DateTime? dob;
  String? phoneNumber;
  String? qualification;
  String? experience;
  String? preferredclass;
  String? medium;
  String? subject;
  String? state;
  String? city;
  String? area;
  String? pincode;
  Map<String, bool>? timeslot;
  String? school;
  String? caddress;
  String? board;
  String? paddress;
  String? photoPath;
  String? aadharFrontPath;
  String? aadharBackPath;
  String? signaturePath;
  bool? agreetoterms;

  Map<String, dynamic> toJson() {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    return {
      'teacherName': teacherName,
      'fathersName': fathersName,
      'mothersName': mothersName,
      'gender': gender,
      'dob': dob != null ? dateFormatter.format(dob!) : null,
      'phoneNumber': phoneNumber,
      'qualification': qualification,
      'experience': experience,
      'preferredclass': preferredclass,
      'medium': medium,
      'subject': subject,
      'school': school,
      'board': board,
      ...?timeslot,
      'state': state,
      'city': city,
      'area': area,
      'pincode': pincode,
      'caddress': caddress,
      'paddress': paddress,
      'photoPath': photoPath,
      'aadharFrontPath': aadharFrontPath,
      'aadharBackPath': aadharBackPath,
      'signaturePath': signaturePath,
      'agreetoterms': agreetoterms,
    };
  }
}

class Location {
  final String name; // City name
  final String state;
  final String pincode;

  Location({
    required this.name,
    required this.state,
    required this.pincode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'],
      state: json['state'],
      pincode: json['pincode'],
    );
  }
}

class TeacherRegistrationPage extends StatefulWidget {
  const TeacherRegistrationPage({super.key});

  @override
  TeacherRegistrationPageState createState() => TeacherRegistrationPageState();
}

class TeacherRegistrationPageState extends State<TeacherRegistrationPage> {
  String? gender;
  DateTime? selectedDOB;
  bool agreeToTerms = false;
  bool isSendingOTP = false;

  final TeacherRegistrationData formData = TeacherRegistrationData();

  final TextEditingController _phoneController = TextEditingController();

  List<Location> locations = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Selected values
  String? selectedState;
  String? selectedCity;
  String? selectedPincode;

  // Filtered lists
  List<String> states = [];
  List<String> cities = [];
  List<String> pincodes = [];
  List<String> _subjects = [];
  List<String> _classes = [];
  bool userSkipped = false;
  List<String> selectedSubjects = [];
  List<String> selectedClass = [];
  List<String> selectedMedium = [];
  List<String> selectedBoard = [];
  bool isLoading = true;
  bool isprofileuploading = false;
  bool isadhaarfuploading = false;
  bool isadhaarbuploading = false;
  bool issignuploading = false;
  bool isprofileEnabled = true;
  bool isadhaarfEnabled = true;
  bool isadhaarbEnabled = true;
  bool issignEnabled = true;
  bool isAdditionalLoading = true;
  dynamic additionals;
  Set<String> selectedSlots = {}; // Store selected time slots
  String? uploadedPath;

  Future<Map<String, List<String>>> fetchAndOrganizeAdditionals() async {
    setState(() {
      isAdditionalLoading = true;
    });
    const String apiUrl = "$baseUrl/get-additionals";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        Map<String, List<String>> organizedData = {};

        for (var item in responseData) {
          String type = item['type'];
          String value = item['value'];

          if (!organizedData.containsKey(type)) {
            organizedData[type] = [];
          }
          organizedData[type]!.add(value);
        }

        return organizedData;
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      return {};
    }
  }

  void organizeAdditionals() async {
    additionals = await fetchAndOrganizeAdditionals();
    setState(() {
      isAdditionalLoading = false;
    });
    print(additionals);
  }

  Future<void> handleUploadFromCamera(String? path) async {
    setState(() {
      if (path == 'photo') {
        isprofileuploading = true;
        isadhaarbEnabled = false;
        isadhaarfEnabled = false;
        issignEnabled = false;
      } else if (path == 'adhaarFront') {
        isadhaarfuploading = true;
        isadhaarbEnabled = false;
        isprofileEnabled = false;
        issignEnabled = false;
      } else if (path == 'adhaarBack') {
        isadhaarbuploading = true;
        isadhaarfEnabled = false;
        isprofileEnabled = false;
        issignEnabled = false;
      } else if (path == 'sign') {
        issignuploading = true;
        isadhaarbEnabled = false;
        isprofileEnabled = false;
        isadhaarfEnabled = false;
      }
    });
    final String result =
        await ImageUploadUtils.uploadSingleImageFromCamera(context);

    if (result != 'null') {
      setState(() {
        if (path == 'photo') {
          formData.photoPath = result;
          isprofileuploading = false;
          isadhaarbEnabled = true;
          isadhaarfEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarFront') {
          formData.aadharFrontPath = result;
          isadhaarfuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarBack') {
          formData.aadharBackPath = result;
          isadhaarbuploading = false;
          isadhaarfEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'sign') {
          formData.signaturePath = result;
          issignuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          isadhaarfEnabled = true;
        }
      });
      showCustomToast(context, 'Image uploaded successfully!');
    } else {
      showCustomToast(context, 'Image upload failed!');
      setState(() {
        if (path == 'photo') {
          isprofileuploading = false;
          isadhaarbEnabled = true;
          isadhaarfEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarFront') {
          isadhaarfuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarBack') {
          isadhaarbuploading = false;
          isadhaarfEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'sign') {
          issignuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          isadhaarfEnabled = true;
        }
      });
    }
  }

  Future<void> handleUploadFromGallery(String? path) async {
    setState(() {
      if (path == 'photo') {
        isprofileuploading = true;
        isadhaarbEnabled = false;
        isadhaarfEnabled = false;
        issignEnabled = false;
      } else if (path == 'adhaarFront') {
        isadhaarfuploading = true;
        isadhaarbEnabled = false;
        isprofileEnabled = false;
        issignEnabled = false;
      } else if (path == 'adhaarBack') {
        isadhaarbuploading = true;
        isadhaarfEnabled = false;
        isprofileEnabled = false;
        issignEnabled = false;
      } else if (path == 'sign') {
        issignuploading = true;
        isadhaarbEnabled = false;
        isprofileEnabled = false;
        isadhaarfEnabled = false;
      }
    });
    final String result =
        await ImageUploadUtils.uploadSingleImageFromGallery(context);

    if (result != 'null') {
      setState(() {
        if (path == 'photo') {
          formData.photoPath = result;
          isprofileuploading = false;
          isadhaarbEnabled = true;
          isadhaarfEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarFront') {
          formData.aadharFrontPath = result;
          isadhaarfuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarBack') {
          formData.aadharBackPath = result;
          isadhaarbuploading = false;
          isadhaarfEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'sign') {
          formData.signaturePath = result;
          issignuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          isadhaarfEnabled = true;
        }
      });
      showCustomToast(context, 'Image uploaded successfully!');
    } else {
      showCustomToast(context, 'Image upload failed!');
      setState(() {
        if (path == 'photo') {
          isprofileuploading = false;
          isadhaarbEnabled = true;
          isadhaarfEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarFront') {
          isadhaarfuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'adhaarBack') {
          isadhaarbuploading = false;
          isadhaarfEnabled = true;
          isprofileEnabled = true;
          issignEnabled = true;
        } else if (path == 'sign') {
          issignuploading = false;
          isadhaarbEnabled = true;
          isprofileEnabled = true;
          isadhaarfEnabled = true;
        }
      });
    }
  }

  Future<void> fetchAllClasses() async {
    final url = Uri.parse('$baseUrl/classes');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (mounted) {
        setState(() {
          final Set<String> uniqueClasses = {};

          for (var course in data) {
            final courseClass =
                course['name'] as String; // Adjust based on API response
            uniqueClasses.add(courseClass);
          }
          _classes = uniqueClasses.toList();
        });
      }
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  Future<void> fetchAllSubjects() async {
    final url = Uri.parse('$baseUrl/subjects');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (mounted) {
        setState(() {
          // Use a Set to ensure unique values
          final Set<String> uniqueCourses = {};
          for (var course in data) {
            // Extract the subject and class
            final subject = course['name'] as String;
            uniqueCourses.add(subject);
          }

          // Convert sets back to lists
          _subjects = uniqueCourses.toList();
        });
      }
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  Future<void> _loadPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPhoneNumber =
        prefs.getString('phone_number'); // Replace with your key
    if (savedPhoneNumber != null) {
      setState(() {
        _phoneController.text = savedPhoneNumber;
        userSkipped = false;
      });
      // Set the text field value
    } else {
      setState(() {
        userSkipped = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    fetchAllClasses();
    fetchAllSubjects();
    fetchLocations();
    organizeAdditionals();
  }

  Future<void> fetchLocations() async {
    const String apiUrl = "$baseUrl/api/city";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Parse the data into a list of Location objects
        locations = data.map((json) => Location.fromJson(json)).toList();

        // Populate states list
        setState(() {
          states = locations.map((loc) => loc.state).toSet().toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load locations");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  void onStateChanged(String? value) {
    setState(() {
      selectedState = value;
      formData.state = selectedState;
      selectedCity = null;
      selectedPincode = null;

      // Filter cities by state
      cities = locations
          .where((loc) => loc.state == value)
          .map((loc) => loc.name)
          .toSet()
          .toList();

      // Clear pincodes
      pincodes = [];
    });
  }

  void onCityChanged(String? value) {
    setState(() {
      selectedCity = value;
      formData.city = selectedCity;
      selectedPincode = null;

      // Filter pincodes by city
      pincodes = locations
          .where((loc) => loc.name == value)
          .map((loc) => loc.pincode)
          .toSet()
          .toList();
    });
  }

  Future<void> postTeacherData({
    required List<TeacherRegistrationData> teacherFormsData,
  }) async {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');

    // Validate the form
    if (!_formKey.currentState!.validate()) {
      showCustomToast(context, 'Please fill all required fields in the form.');
      return; // Stop execution if form validation fails
    }

    for (final teacher in teacherFormsData) {
      if (teacher.photoPath == null || teacher.photoPath!.isEmpty) {
        showCustomToast(context, 'Profile Photo is required.');
        return;
      }
      if (teacher.timeslot == null || teacher.timeslot!.isEmpty) {
        showCustomToast(context, 'Please Select atleast one TimeSlot.');
        return;
      }
      if (teacher.aadharBackPath == null || teacher.aadharBackPath!.isEmpty) {
        showCustomToast(context, 'Adhaar Back Image is required.');
        return;
      }
      if (teacher.aadharFrontPath == null || teacher.aadharFrontPath!.isEmpty) {
        showCustomToast(context, 'Adhaar Front Image is required.');
        return;
      }
      if (teacher.signaturePath == null || teacher.signaturePath!.isEmpty) {
        showCustomToast(context, 'Signature is required.');
        return;
      }
    }

    final Map<String, dynamic> payload = {
      "phone": _phoneController.text,
      "role": "teacher",
      "data": teacherFormsData.map((teacher) {
        return {
          "name": teacher.teacherName,
          "father_name": teacher.fathersName,
          "mother_name": teacher.mothersName,
          "gender": teacher.gender,
          "DOB":
              teacher.dob != null ? dateFormatter.format(teacher.dob!) : null,
          "qualification": teacher.qualification,
          "experience": teacher.experience,
          "class": teacher.preferredclass,
          "medium": teacher.medium,
          "subject": teacher.subject,
          "school": teacher.school,
          "board": teacher.board,
          "state": teacher.state,
          ...teacher.timeslot!,
          "city": teacher.city,
          "area": teacher.area,
          "pincode": teacher.pincode,
          "caddress": teacher.caddress,
          "paddress": teacher.paddress,
          "address": teacher.caddress, // Use common address field if needed
          "time_slot": teacher.signaturePath, // Update dynamically if needed
          "profile": teacher.photoPath,
          "adhaar_front": teacher.aadharFrontPath,
          "adhaar_back": teacher.aadharBackPath,
          "agree_to_terms": teacher.agreetoterms,
        };
      }).toList(),
    };

    // Sending the POST request
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'), // Replace with your API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        print('Data posted successfully: ${response.body}');
        print(payload);

        showCustomToast(context, 'Registration Successful');
        userSkipped
            ? sendOTP(_phoneController.text, context)
            : Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SplashScreen(phone: _phoneController.text),
                ),
              );
      } else if (response.statusCode == 409) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrusirLoginPage()),
        );
        showCustomToast(context, 'User Already Exists!');
        print(payload);
      } else if (response.statusCode == 500) {
        print('Failed to post data: ${response.statusCode}, ${response.body}');
        showCustomToast(context, 'Internal Server Error');
        print(payload);
      }
    } catch (e) {
      print('Error occurred while posting data: $e');
      print(payload);
    }
  }

  Future<void> sendOTP(String phoneNumber, BuildContext context) async {
    try {
      // Immediately navigate to OTP screen with loading state
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

      // Format: +91XXXXXXXXXX
      String formattedPhone = '+91$phoneNumber';

      // Store phone number in shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_number', phoneNumber);

      // Firebase Phone Auth
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          print("Auto-verified: ${credential.smsCode}");
          // Auto-verification will handle navigation automatically
        },
        verificationFailed: (FirebaseAuthException e) {
          Navigator.pop(context); // Return to phone input if verification fails
          print("Firebase OTP Error: ${e.message}");
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
      Navigator.pop(context); // Return to phone input if error occurs
      print("OTP Error: $e");
      showCustomToast(context, 'Failed to send OTP');
    }
  }

  Future<void> _selectDOB(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDOB) {
      setState(() {
        selectedDOB = picked;
        formData.dob = selectedDOB;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
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
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/back_button.png', height: 50)),
            ],
          ),
        ),
        toolbarHeight: 70,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isAdditionalLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : isWeb
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/groupregister.png',
                                width: 400,
                              ),
                            ),
                            // Teacher's basic information
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTextField('Teacher Name',
                                    onChanged: (value) {
                                  formData.teacherName = value;
                                }),
                                const SizedBox(width: 50),
                                _buildTextField("Father's Name",
                                    onChanged: (value) {
                                  formData.fathersName = value;
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTextField("Mother's Name",
                                    onChanged: (value) {
                                  formData.mothersName = value;
                                }),
                                const SizedBox(width: 50),
                                _buildPhoneField('Phone Number'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Gender and DOB Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildDropdownField(
                                    'Gender',
                                    selectedValue: gender,
                                    onChanged: (value) {
                                      setState(() {
                                        gender = value;
                                        formData.gender = gender;
                                      });
                                    },
                                    items: ['Male', 'Female', 'Other'],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: _buildDropdownField(
                                    'Qualification',
                                    selectedValue: formData.qualification,
                                    onChanged: (value) {
                                      setState(() {
                                        formData.qualification = value;
                                      });
                                    },
                                    items: additionals['qualification'],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: _buildDropdownField(
                                    'Experience',
                                    selectedValue: formData.experience,
                                    onChanged: (value) {
                                      setState(() {
                                        formData.experience = value;
                                      });
                                    },
                                    items: additionals['experience'],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextFieldWithIcon(
                                    'DOB',
                                    Icons.calendar_today,
                                    onTap: () => _selectDOB(context),
                                    value: selectedDOB != null
                                        ? "${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}"
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildMultiSelectDropdownField(
                                  'Preferred Board',
                                  selectedValues: selectedBoard,
                                  onChanged: (List<String> values) {
                                    setState(() {
                                      selectedBoard = values;
                                      formData.board = selectedBoard.join(',');
                                    });
                                  },
                                  items: additionals['board'],
                                ),
                                const SizedBox(width: 50),
                                _buildTextField('School Name',
                                    onChanged: (value) {
                                  formData.school = value;
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Dropdowns
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMultiSelectDropdownField(
                                    'Preferred Class',
                                    selectedValues: selectedClass,
                                    onChanged: (List<String> values) {
                                      setState(() {
                                        selectedClass = values;
                                        formData.preferredclass =
                                            selectedClass.join(',');
                                      });
                                    },
                                    items: _classes,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMultiSelectDropdownField(
                                    'Preferred Medium',
                                    selectedValues: selectedMedium,
                                    onChanged: (List<String> values) {
                                      setState(() {
                                        selectedMedium = values;
                                        formData.medium =
                                            selectedMedium.join(',');
                                      });
                                    },
                                    items: additionals['mediums'],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMultiSelectDropdownField(
                                    'Subject',
                                    selectedValues: selectedSubjects,
                                    onChanged: (List<String> values) {
                                      setState(() {
                                        selectedSubjects = values;
                                        formData.subject =
                                            selectedSubjects.join(',');
                                      });
                                    },
                                    items: _subjects,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(
                                    'State',
                                    selectedValue: selectedState,
                                    onChanged: (value) {
                                      onStateChanged(value);
                                    },
                                    items: states,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedState == null) {
                                        showCustomToast(context,
                                            'Please select a state first.');
                                      } else {
                                        null;
                                      }
                                    },
                                    child: _buildDropdownField(
                                      'City/Town',
                                      selectedValue: selectedCity,
                                      onChanged: (value) {
                                        onCityChanged(value);
                                      },
                                      items: cities,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildTextField('Mohalla/Area',
                                      onChanged: (value) {
                                    formData.area = value;
                                  }),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedState == null) {
                                        showCustomToast(context,
                                            'Please select a state first.');
                                      } else if (selectedCity == null) {
                                        showCustomToast(context,
                                            'Please select a city first.');
                                      } else {
                                        null;
                                      }
                                    },
                                    child: _buildDropdownField(
                                      'Pincode',
                                      selectedValue: selectedPincode,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedPincode = value;
                                          formData.pincode = selectedPincode;
                                        });
                                      },
                                      items: pincodes,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Address fields
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      _buildAddressField('Current Full Address',
                                          onChanged: (value) {
                                    formData.caddress = value;
                                  }),
                                ),
                                const SizedBox(width: 50),
                                Expanded(
                                  child: _buildAddressField(
                                      'Permanent Full Address',
                                      onChanged: (value) {
                                    formData.paddress = value;
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Upload Sections
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Text(
                                        'Profile Photo',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    isprofileuploading
                                        ? const CircularProgressIndicator()
                                        : _buildFileUploadField('Upload Image',
                                            width: isWeb ? 170 : 220,
                                            onTap: isprofileEnabled
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      barrierColor: Colors.black
                                                          .withValues(
                                                              alpha: 0.3),
                                                      builder: (BuildContext
                                                          context) {
                                                        return Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          insetPadding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .lightBlue
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromCamera(
                                                                          'photo');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Camera",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
                                                                          fontFamily:
                                                                              'Poppins'),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                // Button for "I'm a Teacher"
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .orange
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromGallery(
                                                                          'photo');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Upload File",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
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
                                                  }
                                                : () {
                                                    showCustomToast(context,
                                                        'Let the previous Upload finish first');
                                                  },
                                            displayPath: formData.photoPath),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Text(
                                        'Aadhar Card Front',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    isadhaarfuploading
                                        ? const CircularProgressIndicator()
                                        : _buildFileUploadField('Upload File',
                                            width: isWeb ? 170 : 220,
                                            onTap: isadhaarfEnabled
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      barrierColor: Colors.black
                                                          .withValues(
                                                              alpha: 0.3),
                                                      builder: (BuildContext
                                                          context) {
                                                        return Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          insetPadding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .lightBlue
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromCamera(
                                                                          'adhaarFront');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Camera",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
                                                                          fontFamily:
                                                                              'Poppins'),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                // Button for "I'm a Teacher"
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .orange
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromGallery(
                                                                          'adhaarFront');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Upload File",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
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
                                                  }
                                                : () {
                                                    showCustomToast(context,
                                                        'Let the previous Upload finish first');
                                                  },
                                            displayPath:
                                                formData.aadharFrontPath),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Text(
                                        'Aadhar Card Back',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    isadhaarbuploading
                                        ? const CircularProgressIndicator()
                                        : _buildFileUploadField('Upload File',
                                            width: isWeb ? 170 : 220,
                                            onTap: isadhaarbEnabled
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      barrierColor: Colors.black
                                                          .withValues(
                                                              alpha: 0.3),
                                                      builder: (BuildContext
                                                          context) {
                                                        return Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          insetPadding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .lightBlue
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromCamera(
                                                                          'adhaarBack');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Camera",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
                                                                          fontFamily:
                                                                              'Poppins'),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                // Button for "I'm a Teacher"
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .orange
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromGallery(
                                                                          'adhaarBack');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Upload File",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
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
                                                  }
                                                : () {
                                                    showCustomToast(context,
                                                        'Let the previous Upload finish first');
                                                  },
                                            displayPath:
                                                formData.aadharBackPath),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Text(
                                        'Signature',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    issignuploading
                                        ? const CircularProgressIndicator()
                                        : _buildFileUploadField('Upload Image',
                                            onTap: issignEnabled
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      barrierColor: Colors.black
                                                          .withValues(
                                                              alpha: 0.3),
                                                      builder: (BuildContext
                                                          context) {
                                                        return Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          insetPadding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .lightBlue
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromCamera(
                                                                          'sign');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Camera",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
                                                                          fontFamily:
                                                                              'Poppins'),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                // Button for "I'm a Teacher"
                                                                Container(
                                                                  width: 200,
                                                                  height: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .orange
                                                                        .shade100,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            22),
                                                                  ),
                                                                  child:
                                                                      TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      handleUploadFromGallery(
                                                                          'sign');
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      "Upload File",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18,
                                                                          color: Colors
                                                                              .black,
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
                                                  }
                                                : () {
                                                    showCustomToast(context,
                                                        'Let the previous Upload finish first');
                                                  },
                                            width: isWeb ? 170 : 220,
                                            displayPath:
                                                formData.signaturePath),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            SingleChildScrollView(
                                child: TimeSlotField(
                                    formData: formData, isWeb: isWeb)),
                            const SizedBox(height: 50),

                            // Terms and Conditions Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: agreeToTerms,
                                  onChanged: (bool? value) {
                                    if (!agreeToTerms) {
                                      _showTermsPopup(); // Show popup first before allowing agreement
                                    } else {
                                      setState(() {
                                        agreeToTerms =
                                            false; // Allow unchecking directly
                                      });
                                    }
                                  },
                                ),
                                const Text('I agree with the ',
                                    style: TextStyle(fontSize: 20)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TrusirTermsWidget(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Terms and Conditions',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            // Registration Fee
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Center(
                                  child: Text(
                                    'Free',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20.0,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Center(
                                  child: Text(
                                    '299 ',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.grey.shade700,
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    ' Registration Fee',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20.0,
                                      color: Colors.purple.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Register Button
                            _buildRegisterButton(context),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/groupregister.png',
                              width: 386,
                              height: 261,
                            ),
                          ),
                          // Teacher's basic information
                          _buildTextField('Teacher Name', onChanged: (value) {
                            formData.teacherName = value;
                          }),
                          const SizedBox(height: 14),
                          _buildTextField("Father's Name", onChanged: (value) {
                            formData.fathersName = value;
                          }),
                          const SizedBox(height: 14),
                          _buildTextField("Mother's Name", onChanged: (value) {
                            formData.mothersName = value;
                          }),
                          const SizedBox(height: 14),
                          // Gender and DOB Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  'Gender',
                                  selectedValue: gender,
                                  onChanged: (value) {
                                    setState(() {
                                      gender = value;
                                      formData.gender = gender;
                                    });
                                  },
                                  items: ['Male', 'Female', 'Other'],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildTextFieldWithIcon(
                                  'DOB',
                                  Icons.calendar_today,
                                  onTap: () => _selectDOB(context),
                                  value: selectedDOB != null
                                      ? "${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}"
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildPhoneField('Phone Number'),
                          const SizedBox(height: 14),
                          _buildDropdownField(
                            'Qualification',
                            selectedValue: formData.qualification,
                            onChanged: (value) {
                              setState(() {
                                formData.qualification = value;
                              });
                            },
                            items: additionals['qualification'] ?? [],
                          ),
                          const SizedBox(height: 14),
                          _buildDropdownField(
                            'Experience',
                            selectedValue: formData.experience,
                            onChanged: (value) {
                              setState(() {
                                formData.experience = value;
                              });
                            },
                            items: additionals['experience'] ?? [],
                          ),
                          const SizedBox(height: 14),
                          _buildMultiSelectDropdownField(
                            'Preferred Board',
                            selectedValues: selectedBoard,
                            onChanged: (List<String> values) {
                              setState(() {
                                selectedBoard = values;
                                formData.board = selectedBoard.join(',');
                              });
                            },
                            items: additionals['board'] ?? [],
                          ),
                          const SizedBox(height: 14),
                          _buildTextField('School Name', onChanged: (value) {
                            formData.school = value;
                          }),
                          const SizedBox(height: 14),
                          // Dropdowns
                          _buildMultiSelectDropdownField(
                            'Preferred Class',
                            selectedValues: selectedClass,
                            onChanged: (List<String> values) {
                              setState(() {
                                selectedClass = values;
                                formData.preferredclass =
                                    selectedClass.join(',');
                              });
                            },
                            items: _classes,
                          ),
                          const SizedBox(height: 14),
                          _buildMultiSelectDropdownField(
                            'Preferred Medium',
                            selectedValues: selectedMedium,
                            onChanged: (List<String> values) {
                              setState(() {
                                selectedMedium = values;
                                formData.medium = selectedMedium.join(',');
                              });
                            },
                            items: additionals['mediums'] ?? [],
                          ),
                          const SizedBox(height: 14),
                          _buildMultiSelectDropdownField(
                            'Subject',
                            selectedValues: selectedSubjects,
                            onChanged: (List<String> values) {
                              setState(() {
                                selectedSubjects = values;
                                formData.subject = selectedSubjects.join(',');
                              });
                            },
                            items: _subjects,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdownField(
                            'State',
                            selectedValue: selectedState,
                            onChanged: (value) {
                              onStateChanged(value);
                            },
                            items: states,
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () {
                              if (selectedState == null) {
                                showCustomToast(
                                    context, 'Please select a state first.');
                              } else {
                                null;
                              }
                            },
                            child: _buildDropdownField(
                              'City/Town',
                              selectedValue: selectedCity,
                              onChanged: (value) {
                                onCityChanged(value);
                              },
                              items: cities,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildTextField('Mohalla/Area', onChanged: (value) {
                            formData.area = value;
                          }),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () {
                              if (selectedState == null) {
                                showCustomToast(
                                    context, 'Please select a state first.');
                              } else if (selectedCity == null) {
                                showCustomToast(
                                    context, 'Please select a city first.');
                              } else {
                                null;
                              }
                            },
                            child: _buildDropdownField(
                              'Pincode',
                              selectedValue: selectedPincode,
                              onChanged: (value) {
                                setState(() {
                                  selectedPincode = value;
                                  formData.pincode = selectedPincode;
                                });
                              },
                              items: pincodes,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Address fields
                          _buildAddressField('Current Full Address',
                              onChanged: (value) {
                            formData.caddress = value;
                          }),
                          const SizedBox(height: 14),
                          _buildAddressField('Permanent Full Address',
                              onChanged: (value) {
                            formData.paddress = value;
                          }),
                          const SizedBox(height: 20),

                          // Upload Sections
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 58),
                                child: Text(
                                  'Profile Photo',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              isprofileuploading
                                  ? const CircularProgressIndicator()
                                  : _buildFileUploadField('Upload Image',
                                      width: isWeb ? 150 : 171,
                                      onTap: isprofileEnabled
                                          ? () {
                                              showDialog(
                                                context: context,
                                                barrierColor: Colors.black
                                                    .withValues(alpha: 0.3),
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    insetPadding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .lightBlue
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromCamera(
                                                                    'photo');
                                                              },
                                                              child: const Text(
                                                                "Camera",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
                                                                    fontFamily:
                                                                        'Poppins'),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 16),
                                                          // Button for "I'm a Teacher"
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .orange
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromGallery(
                                                                    'photo');
                                                              },
                                                              child: const Text(
                                                                "Upload File",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
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
                                            }
                                          : () {
                                              showCustomToast(context,
                                                  'Let the previous Upload finish first');
                                            },
                                      displayPath: formData.photoPath),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: Text(
                                  'Aadhar Card Front',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              isadhaarfuploading
                                  ? const CircularProgressIndicator()
                                  : _buildFileUploadField('Upload File',
                                      width: isWeb ? 150 : 170,
                                      onTap: isadhaarfEnabled
                                          ? () {
                                              showDialog(
                                                context: context,
                                                barrierColor: Colors.black
                                                    .withValues(alpha: 0.3),
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    insetPadding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .lightBlue
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromCamera(
                                                                    'adhaarFront');
                                                              },
                                                              child: const Text(
                                                                "Camera",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
                                                                    fontFamily:
                                                                        'Poppins'),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 16),
                                                          // Button for "I'm a Teacher"
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .orange
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromGallery(
                                                                    'adhaarFront');
                                                              },
                                                              child: const Text(
                                                                "Upload File",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
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
                                            }
                                          : () {
                                              showCustomToast(context,
                                                  'Let the previous Upload finish first');
                                            },
                                      displayPath: formData.aadharFrontPath),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: Text(
                                  'Aadhar Card Back',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              isadhaarbuploading
                                  ? const CircularProgressIndicator()
                                  : _buildFileUploadField('Upload File',
                                      width: isWeb ? 150 : 170,
                                      onTap: isadhaarbEnabled
                                          ? () {
                                              showDialog(
                                                context: context,
                                                barrierColor: Colors.black
                                                    .withValues(alpha: 0.3),
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    insetPadding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .lightBlue
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromCamera(
                                                                    'adhaarBack');
                                                              },
                                                              child: const Text(
                                                                "Camera",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
                                                                    fontFamily:
                                                                        'Poppins'),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 16),
                                                          // Button for "I'm a Teacher"
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .orange
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromGallery(
                                                                    'adhaarBack');
                                                              },
                                                              child: const Text(
                                                                "Upload File",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
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
                                            }
                                          : () {
                                              showCustomToast(context,
                                                  'Let the previous Upload finish first');
                                            },
                                      displayPath: formData.aadharBackPath),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 79),
                                child: Text(
                                  'Signature',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              issignuploading
                                  ? const CircularProgressIndicator()
                                  : _buildFileUploadField('Upload Image',
                                      onTap: issignEnabled
                                          ? () {
                                              showDialog(
                                                context: context,
                                                barrierColor: Colors.black
                                                    .withValues(alpha: 0.3),
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    insetPadding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .lightBlue
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromCamera(
                                                                    'sign');
                                                              },
                                                              child: const Text(
                                                                "Camera",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
                                                                    fontFamily:
                                                                        'Poppins'),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 16),
                                                          // Button for "I'm a Teacher"
                                                          Container(
                                                            width: 200,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .orange
                                                                  .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          22),
                                                            ),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                handleUploadFromGallery(
                                                                    'sign');
                                                              },
                                                              child: const Text(
                                                                "Upload File",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Colors
                                                                        .black,
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
                                            }
                                          : () {
                                              showCustomToast(context,
                                                  'Let the previous Upload finish first');
                                            },
                                      width: isWeb ? 150 : 171,
                                      displayPath: formData.signaturePath),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TimeSlotField(formData: formData, isWeb: isWeb),
                          const SizedBox(height: 5),

                          // Terms and Conditions Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: agreeToTerms,
                                onChanged: (bool? value) {
                                  if (!agreeToTerms) {
                                    _showTermsPopup(); // Show popup first before allowing agreement
                                  } else {
                                    setState(() {
                                      agreeToTerms =
                                          false; // Allow unchecking directly
                                    });
                                  }
                                },
                              ),
                              const Text(
                                'I agree with the ',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showTermsPopup(); // Open popup when clicking on Terms
                                },
                                child: const Text(
                                  'Terms and Conditions',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontFamily: 'Poppins',
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Registration Fee
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Center(
                                child: Text(
                                  'Free',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20.0,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Center(
                                child: Text(
                                  '299 ',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.grey.shade700,
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  ' Registration Fee',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20.0,
                                    color: Colors.purple.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Register Button
                          _buildRegisterButton(context),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  void _showTermsPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Please read and accept the",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Terms and Conditions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 15),
                const SizedBox(
                  height: 500,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("1. About Trusir",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                            "Trusir is a platform that connects students (from kids to teenagers) with qualified tutors for offline, in-person home tuition in subjects like Hindi, English, Math, Science, and Social Science. Tutors are independent service providers, not employees of Trusir.",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 12),
                          Text("2. Eligibility & Registration",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• You must be at least 18 years old to register as a tutor.\n"
                              "• You must provide accurate, complete, and verifiable information including qualifications, ID proof, and address.\n"
                              "• Trusir reserves the right to accept or reject tutor registrations at its sole discretion.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("3. Role & Responsibilities of Tutors",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• Provide quality offline tutoring sessions at the student’s location as per the agreed schedule.\n"
                              "• Maintain a professional, respectful, and safe teaching environment.\n"
                              "• Inform Trusir and the student/parent in advance if a session needs to be rescheduled.\n"
                              "• Do not share personal contact details unnecessarily or request direct payments from parents/students.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("4. Prohibited Conduct: Direct Dealings",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• Strictly prohibited: After being introduced to a student/parent through Trusir, you must not work with them independently, bypassing Trusir, for any future sessions.\n"
                              "• Attempting to arrange tuition directly with a student or parent introduced through Trusir will result in immediate blacklisting and removal from the platform, and possible legal action.\n"
                              "• This restriction applies during your time on Trusir and for 12 months after your last session with that student.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("5. Payments",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• All payments for sessions must be handled through Trusir.\n"
                              "• You will receive payment after deduction of Trusir’s service fee/commission.\n"
                              "• Delays caused by incomplete attendance updates or policy violations may result in withheld payments.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("6. Code of Conduct",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• Tutors must behave professionally and respectfully with students and parents.\n"
                              "• Any form of harassment, misconduct, or unprofessional behavior may lead to permanent suspension and reporting to relevant authorities.\n"
                              "• You must not promote any external services, platforms, or personal business while working through Trusir.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("7. Background & Verification",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• Trusir may conduct background checks for safety and quality purposes.\n"
                              "• Falsifying documents or information will lead to immediate termination and possible legal action.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("8. Termination of Association",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• Trusir reserves the right to suspend or remove any tutor who violates these Terms, receives consistent negative feedback, or engages in unethical behavior.\n"
                              "• Tutors can deactivate their profile by submitting a written request to support@trusir.com.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("9. Limitation of Liability",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• Trusir is not responsible for any injury, loss, or dispute arising from your sessions with students.\n"
                              "• You are responsible for your conduct, safety, and interactions during offline sessions.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("10. Modification of Terms",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• Trusir reserves the right to modify these Terms at any time.\n"
                              "• Continued use of the platform after updates implies acceptance of the revised Terms.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("11. Contact Us",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "For questions or support:\n"
                              "Email: support@trusir.com\n"
                              "Website: www.trusir.com\n"
                              "App Support: Available through the Trusir app (Android & iOS)",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 12),
                          Text("12. Jurisdiction",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              )),
                          SizedBox(height: 6),
                          Text(
                              "• All disputes arising from the use of our services shall be subject to the exclusive jurisdiction of the courts at Motihari, Bihar.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      agreeToTerms = true;
                      formData.agreetoterms = agreeToTerms;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text(
                    "I accept",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          formData.agreetoterms == true
              ? postTeacherData(teacherFormsData: [formData])
              : showCustomToast(
                  context, 'Please Agree to Terms and Conditions');
        },
        child: Image.asset(
          'assets/register.png',
          width: double.infinity,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildAddressField(
    String hintText, {
    required ValueChanged<String> onChanged,
  }) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return Container(
      width: isWeb ? 700 : double.infinity,
      height: 150, // Set a fixed height for the container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        validator: _validateRequired,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,

        maxLines: null, // Allows the text to wrap and grow vertically
        textAlignVertical:
            TextAlignVertical.top, // Ensures text starts from the top
        expands: true, // Makes the TextField expand to fit its parent container
        decoration: InputDecoration(
          labelText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12, // Adjust vertical padding for better alignment
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hintText, {
    double height = 48,
    required ValueChanged<String> onChanged,
  }) {
    bool isWeb = MediaQuery.of(context).size.width > 500;
    return Container(
      height: height,
      width: isWeb ? 500 : 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        validator: _validateRequired,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPhoneField(
    String hintText,
  ) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return Container(
      height: 48,
      width: isWeb ? 550 : double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200, blurRadius: 4, spreadRadius: 2),
        ],
      ),
      child: TextFormField(
        validator: _validatePhone,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        enabled: userSkipped,
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        buildCounter: (_,
                {required currentLength, required isFocused, maxLength}) =>
            null, // Hides counter
        onChanged: (value) {
          if (value.length == 10) {
            FocusScope.of(context).unfocus(); // Dismiss keyboard after 6 digits
          }
        },
        decoration: InputDecoration(
          labelText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildMultiSelectDropdownField(
    String hintText, {
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
    required List<String> items,
  }) {
    String selectedText = selectedValues.join(', ');

    return StatefulBuilder(
      builder: (context, setState) {
        bool isWeb = MediaQuery.of(context).size.width > 600;
        return Container(
          height: 48,
          width: isWeb ? 550 : double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (selectedValues.isEmpty) {
                return 'Please select at least one option';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: hintText,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              isDense: true,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: StatefulBuilder(
                      builder: (context, setStateInner) {
                        return CheckboxListTile(
                          title: Text(
                            item,
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                          value: selectedValues.contains(item),
                          onChanged: (bool? isChecked) {
                            if (isChecked == true) {
                              if (!selectedValues.contains(item)) {
                                selectedValues.add(item);
                              }
                            } else {
                              selectedValues.remove(item);
                            }
                            // Update the concatenated text
                            selectedText = selectedValues.join(', ');

                            // Pass the updated list to the parent
                            onChanged(selectedValues);
                            setStateInner(() {}); // Update the UI for this item
                            setState(() {}); // Update the display string
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                )
                .toList(),
            onChanged: (_) {
              // No need for action here since selection happens in the checkbox
            },
            isExpanded: true,
            value: null,
            hint: selectedText.isNotEmpty
                ? Text(
                    selectedText,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w400),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDropdownField(
    String hintText, {
    String? selectedValue,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return Container(
      height: 48,
      width: isWeb ? 700 : double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200, blurRadius: 4, spreadRadius: 2),
        ],
      ),
      child: DropdownButtonFormField<String>(
        validator: _validateDropdown,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        value: selectedValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          isDense: true,
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTextFieldWithIcon(
    String hintText,
    IconData icon, {
    required VoidCallback onTap,
    String? value,
  }) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return Container(
      height: 48,
      width: 184,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        validator: _validateRequired,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        readOnly: true, // Ensures the field is not editable
        onTap: onTap,
        decoration: InputDecoration(
          labelText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: isWeb ? 21 : 0),
          suffixIcon: Icon(icon),
          isDense: true,
        ),
        controller: TextEditingController(text: value ?? ''),
      ),
    );
  }

  Widget _buildFileUploadField(String placeholder,
      {required displayPath,
      required VoidCallback? onTap,
      required double width}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200, blurRadius: 4, spreadRadius: 2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: displayPath == null
                  ? Text(placeholder,
                      style: const TextStyle(color: Colors.grey))
                  : Image.network(
                      displayPath,
                      fit: BoxFit.fill,
                    ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Icons.upload_file),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    } else if (value.length != 10 || !RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select an option';
    }
    return null;
  }
}

class TimeSlotField extends StatefulWidget {
  final dynamic formData;
  final bool isWeb; // Assuming you have a FormData class with timeslot field

  const TimeSlotField({super.key, required this.formData, required this.isWeb});

  @override
  TimeSlotFieldState createState() => TimeSlotFieldState();
}

class TimeSlotFieldState extends State<TimeSlotField> {
  final Map<String, String> slotToApiKey = {
    '6-7 AM': 't6am_7am',
    '7-8 AM': 't7am_8am',
    '8-9 AM': 't8am_9am',
    '9-10 AM': 't9am_10am',
    '10-11 AM': 't10am_11am',
    '11-12 PM': 't11am_12pm',
    '12-1 PM': 't12pm_1pm',
    '1-2 PM': 't1pm_2pm',
    '2-3 PM': 't2pm_3pm',
    '3-4 PM': 't3pm_4pm',
    '4-5 PM': 't4pm_5pm',
    '5-6 PM': 't5pm_6pm',
    '6-7 PM': 't6pm_7pm',
    '7-8 PM': 't7pm_8pm',
  };

  final List<String> morningSlots = [
    '6-7 AM',
    '7-8 AM',
    '8-9 AM',
    '9-10 AM',
    '10-11 AM',
    '11-12 PM'
  ];
  final List<String> afternoonSlots = [
    '12-1 PM',
    '1-2 PM',
    '2-3 PM',
    '3-4 PM',
    '4-5 PM'
  ];
  final List<String> eveningSlots = ['5-6 PM', '6-7 PM', '7-8 PM'];

  final Set<String> selectedSlots = {};

  void toggleSelection(String slot) {
    setState(() {
      if (selectedSlots.contains(slot)) {
        selectedSlots.remove(slot);
      } else {
        selectedSlots.add(slot);
      }

      // Update the timeslot field in the form data
      widget.formData.timeslot = slotToApiKey.map((key, apiKey) {
        return MapEntry(apiKey, selectedSlots.contains(key));
      });
    });
  }

  Widget buildSlot(String slot) {
    return GestureDetector(
      onTap: () => toggleSelection(slot),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 5,
        ),
        padding: const EdgeInsets.all(9.0),
        decoration: BoxDecoration(
          color: selectedSlots.contains(slot)
              ? const Color.fromARGB(255, 127, 0, 195)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey),
        ),
        child: Center(
          child: Text(
            slot,
            style: TextStyle(
              color: selectedSlots.contains(slot) ? Colors.white : Colors.black,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(5),
      child: widget.isWeb
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hours of Availability',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20.0,
                    color: Colors.purple.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Morning Hours',
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8.0),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: morningSlots.map(buildSlot).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Afternoon Hours',
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8.0),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: afternoonSlots.map(buildSlot).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evening Hours',
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8.0),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: eveningSlots.map(buildSlot).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hours of Availability',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20.0,
                    color: Colors.purple.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Morning Hours',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: morningSlots.map(buildSlot).toList(),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Afternoon Hours',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: afternoonSlots.map(buildSlot).toList(),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Evening Hours',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: eveningSlots.map(buildSlot).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
