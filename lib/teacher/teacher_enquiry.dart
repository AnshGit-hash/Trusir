import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/student/student_registration.dart';
import 'package:trusir/teacher/teacher_homepage.dart';
import 'package:trusir/common/service_unavailable_page.dart';

class TeacherEnquiry {
  String? name;
  String? qualification;
  String? city;
  String? pincode;
  String? gender;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qualification': qualification,
      'city': city,
      'pincode': pincode,
      'gender': gender
    };
  }
}

class TeacherEnquiryPage extends StatefulWidget {
  TeacherEnquiryPage({super.key});

  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _qualificationcontroller =
      TextEditingController();
  final TextEditingController _citycontroller = TextEditingController();
  final TextEditingController _pincodecontroller = TextEditingController();

  final TeacherEnquiry formData = TeacherEnquiry();

  @override
  State<TeacherEnquiryPage> createState() => _TeacherEnquiryPageState();
}

class _TeacherEnquiryPageState extends State<TeacherEnquiryPage> {
  bool isMaleSelected = false;
  bool isFemaleSelected = false;
  bool isLocationServiceable = false;
  List<Location> locations = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchLocations();
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
      } else {
        throw Exception("Failed to load locations");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _onEnquire() {
    if (!_formKey.currentState!.validate()) {
      showCustomToast(context, 'Fill all the Required Fields');
      return;
    }
    setState(() {
      widget.formData.name = widget._namecontroller.text;
      widget.formData.qualification = widget._qualificationcontroller.text;
      widget.formData.city = widget._citycontroller.text;
      widget.formData.pincode = widget._pincodecontroller.text;
    });

    isLocationServiceable = locations
        .any((location) => location.pincode == widget.formData.pincode);

    if (widget.formData.gender == null) {
      showCustomToast(context, 'Select a Gender');
      return;
    }
    submitForm(context, isLocationServiceable);
  }

  Future<void> submitForm(BuildContext context, bool serviceable) async {
    final url = Uri.parse('$baseUrl/api/enquiry-teacher');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(widget.formData.toJson());

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (!serviceable) {
        if (response.statusCode == 200) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const ServiceUnavailablePage()),
            (Route<dynamic> route) => false,
          );
          showCustomToast(context, 'Form Submitted Successfully');
        } else {
          showCustomToast(context, 'Failed to submit form: ${response.body}');
        }
      } else if (serviceable) {
        if (response.statusCode == 200) {
          _showThankYouPopup(context);
          showCustomToast(context, 'Form Submitted Successfully');
        } else {
          showCustomToast(context, 'Failed to submit form: ${response.body}');
        }
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void _showThankYouPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/check.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thank You!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your enquiry has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Teacherhomepage(
                          enableReg: true,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Teacherhomepage(
            enableReg: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 1.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 50,
                    maxWidth: 50,
                  ),
                  child: Image.asset(
                    'assets/back_button.png',
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'Teacher Enquiry',
                style: TextStyle(
                  color: Color(0xFF48116A),
                  fontSize: 25,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 50,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.9,
                      maxHeight: screenHeight * 0.4,
                    ),
                    child: Image.asset(
                      'assets/Teacher_Enquiry2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                _buildTextFieldWithBackground(
                    hintText: 'Teacher Name',
                    controllers: widget._namecontroller),
                const SizedBox(height: 15),

                // Gender Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildGenderCheckbox(
                      label: "Male",
                      value: isMaleSelected,
                      onChanged: (value) {
                        setState(() {
                          isMaleSelected = value!;
                          if (value) {
                            isFemaleSelected = false;
                            widget.formData.gender = 'Male';
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildGenderCheckbox(
                      label: "Female",
                      value: isFemaleSelected,
                      onChanged: (value) {
                        setState(() {
                          isFemaleSelected = value!;
                          if (value) {
                            isMaleSelected = false;
                            widget.formData.gender = 'Female';
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildTextFieldWithBackground(
                    hintText: 'Qualification',
                    controllers: widget._qualificationcontroller),
                const SizedBox(height: 20),

                _buildTextFieldWithBackground(
                    hintText: 'City / Town',
                    controllers: widget._citycontroller),
                const SizedBox(height: 20),

                _buildPinFieldWithBackground(
                    hintText: 'Pincode',
                    controllers: widget._pincodecontroller),
                SizedBox(height: screenHeight * 0.03),

                // Enquire Button
                Center(
                  child: GestureDetector(
                    onTap: _onEnquire,
                    child: SizedBox(
                      width: kIsWeb ? 300.0 : 300.0,
                      height: kIsWeb ? 80.0 : 70.0,
                      child: Image.asset(
                        'assets/enquire.png',
                        fit: BoxFit.contain,
                      ),
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

  Widget _buildTextFieldWithBackground(
      {required String hintText, required TextEditingController controllers}) {
    return Container(
      height: 55,
      width: double.infinity,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required Field';
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: controllers,
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPinFieldWithBackground({
    required String hintText,
    required TextEditingController controllers,
  }) {
    return Container(
      width: double.infinity,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required Field';
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textCapitalization: TextCapitalization.words,
        controller: controllers,
        keyboardType: TextInputType.number,
        maxLength: 6,
        buildCounter: (_,
                {required currentLength, required isFocused, maxLength}) =>
            null,
        onChanged: (value) {
          if (value.length == 6) {
            FocusScope.of(context).unfocus();
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildGenderCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.3,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins-SemiBold',
            fontSize: 16,
            color: Color(0xFF7E7E7E),
          ),
        ),
      ],
    );
  }
}
