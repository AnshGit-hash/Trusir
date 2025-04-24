import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:trusir/common/api.dart';

class AttendanceRecord {
  final int id;
  final String slotTime;
  final String amountAddedtoTeacher;
  final String studentID;
  final String teacherID;
  final String date;
  final String slotID;
  final String status;

  AttendanceRecord({
    required this.id,
    required this.slotTime,
    required this.amountAddedtoTeacher,
    required this.studentID,
    required this.teacherID,
    required this.date,
    required this.slotID,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      slotTime: json['slotTime'] ?? 'No time alloted',
      amountAddedtoTeacher: json['amount_added_to_teacher'],
      studentID: json['studentID'],
      teacherID: json['teacherID'],
      date: json['date'],
      slotID: json['slotID'],
      status: json['status'],
    );
  }
}

class Course {
  final int id;
  final String courseID;
  final String courseName;
  final String teacherName;
  final String teacherID;
  final String studentID;
  final String image;
  final String studentName;
  final String timeSlot;

  Course({
    required this.id,
    required this.courseID,
    required this.courseName,
    required this.teacherName,
    required this.teacherID,
    required this.studentID,
    required this.image,
    required this.studentName,
    required this.timeSlot,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      courseID: json['courseID'],
      courseName: json['courseName'],
      teacherName: json['teacherName'],
      teacherID: json['teacherID'],
      studentID: json['StudentID'],
      image: json['image'],
      studentName: json['StudentName'],
      timeSlot: json['timeSlot'],
    );
  }
}

class AttendancePage extends StatefulWidget {
  final String userID;
  const AttendancePage({super.key, required this.userID});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = DateTime.now();
  int selectedCourseIndex = 0;
  int selectedSlotIndex = 0;
  bool isWeb = false;
  Map<int, Map<String, String>> _attendanceData = {};
// Day: Status
  Map<String, int> _summaryData = {}; // Summary details
  List<String> weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  List<Map<String, String>> slots = [];
  String? selectedslotID = '';

  Future<List<Course>> fetchCourses() async {
    final url = Uri.parse(
        '$baseUrl/get-individual-slots/${widget.userID}'); // Replace with your API URL
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (mounted) {
        setState(() {
          slots = data.map((course) {
            return {
              'courseName': course['courseName'] as String,
              'timeSlot': course['timeSlot'] as String,
              'slotID': course['id']
                  .toString(), // Converting 'id' to String for uniformity
            };
          }).toList();
        });
      }
      setState(() {
        selectedslotID = slots[0]['slotID'];
      });
      print(selectedslotID);
      return data.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  DateTime get _firstDayOfMonth {
    return DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  int get _daysInMonth {
    return DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
  }

  int get _startingWeekday {
    return _firstDayOfMonth.weekday % 7; // Adjust for week starting Sunday
  }

  List<int> get dates {
    return List.generate(_daysInMonth, (index) => index + 1);
  }

  String get _monthYearString {
    return "${getMonthName(_selectedDate.month)} ${_selectedDate.year}";
  }

  @override
  void initState() {
    super.initState();
    initializeData();
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

  Future<void> initializeData() async {
    try {
      await fetchCourses(); // Wait for fetchCourses to complete
      _fetchAttendanceData(
          selectedslotID!); // Call _fetchAttendanceData after fetchCourses
    } catch (error) {
      print('Error during initialization: $error');
    }
  }

  Future<List<AttendanceRecord>> fetchAttendanceRecords({
    required String slotID,
    required int year,
    required int month,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/view-attendance/$slotID/$year/${month.toString().padLeft(2, '0')}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load attendance records. Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching attendance records: $error');
    }
  }

// Process the new API response format
  Map<int, Map<String, String>> processAttendanceData(
      List<AttendanceRecord> records) {
    Map<int, Map<String, String>> processedData = {};

    for (var record in records) {
      // Extract the day from the date string (format: "2025-04-10")
      int day = int.parse(record.date.split('-')[2]);

      // Parse the full date to get the weekday
      DateTime date = DateTime.parse(record.date);
      String dayName = _getDayName(date.weekday);

      // Map the status to match your existing UI expectations
      String status = record.status == 'P'
          ? 'present'
          : (record.status == 'A' ? 'absent' : 'No class');

      processedData[day] = {
        'id': record.slotID.toString(),
        'status': status,
        'date': record.date,
        'day': dayName, // Add the day name here
      };
    }

    return processedData;
  }

  Future<void> _fetchAttendanceData(String selectedslotID) async {
    final month = _selectedDate.month;
    final year = _selectedDate.year;

    setState(() {
      _attendanceData.clear(); // Clear old data before fetching new data
    });

    try {
      final records = await fetchAttendanceRecords(
        slotID: selectedslotID,
        year: year,
        month: month,
      );

      if (records.isEmpty) {
        _showNoDataMessage();
        return;
      }

      setState(() {
        _attendanceData = processAttendanceData(records);
        print(_attendanceData);
      });

      _updateSummary(); // Update summary after fetching data
    } catch (error) {
      print("Error fetching attendance data: $error");
      _showNoDataMessage();
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[weekday % 7];
  }

  void _showNoDataMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No attendance data available.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> markAbsent({
    required String date,
    required String slotID,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/mark-absent/$date/${widget.userID}/$slotID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Fluttertoast.showToast(msg: data['message']);
        setState(() {
          // Update the status locally
          _fetchAttendanceData(selectedslotID!);
          _updateSummary(); // Update the summary
        });
      } else {
        throw Exception('Failed to mark absent Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error while marking absent: $error');
    }
  }

  Future<void> markPresent({
    required String date,
    required String slotID,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/mark-present/$date/${widget.userID}/$slotID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Fluttertoast.showToast(msg: data['message']);
        setState(() {
          // Update the status locally
          _fetchAttendanceData(selectedslotID!);
          _updateSummary(); // Update the summary
        });
      } else {
        throw Exception('Failed to mark absent Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error while marking absent: $error');
    }
  }

  void _navigateToYearMonthPicker(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YearMonthPicker(
          selectedYear: _selectedDate.year,
          selectedMonth: _selectedDate.month,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDate =
            DateTime(result['year'], result['month'], _selectedDate.day);
        _fetchAttendanceData(selectedslotID!);
        _updateSummary();
      });
    }
  }

  void _prevMonth() {
    setState(() {
      if (_selectedDate.month == 1) {
        _selectedDate = DateTime(
            _selectedDate.year - 1, 12); // Go to December of the previous year
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      }
      _fetchAttendanceData(selectedslotID!);
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedDate.month == 12) {
        _selectedDate = DateTime(
            _selectedDate.year + 1, 1); // Go to January of the next year
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      }
      _fetchAttendanceData(selectedslotID!);
    });
  }

  void _updateSummary() {
    int totalClassesTaken = 0;
    int presentCount = 0;
    int absentCount = 0;
    int classNotTakenCount = 0;

    _attendanceData.forEach((_, dateData) {
      // Extract the status from the nested map
      String? status = dateData['status'];

      if (status != null) {
        totalClassesTaken++;
        if (status == 'present') {
          presentCount++;
        } else if (status == 'absent') {
          absentCount++;
        } else if (status == 'No class') {
          classNotTakenCount++;
        }
      }
    });

    setState(() {
      _summaryData = {
        'total_classes_taken': totalClassesTaken,
        'present': presentCount,
        'absent': absentCount,
        'No class': classNotTakenCount,
      };
    });
  }

  String getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600;
    return Scaffold(
        backgroundColor: Colors.grey[50],
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
                  'Attendance',
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
            child: isWeb
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 15, top: 5, right: 15),
                          child: _buildSlotList(),
                        ),
                        // Calendar Section
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 15, bottom: 8, right: 20),
                          child: Container(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            width: 420,
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize:
                                  MainAxisSize.min, // Allow dynamic height
                              children: [
                                // Calendar Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.arrow_back_ios_outlined,
                                          size: 15),
                                      onPressed: _prevMonth,
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          _navigateToYearMonthPicker(context),
                                      child: Text(_monthYearString,
                                          style: const TextStyle(fontSize: 17)),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.arrow_forward_ios_outlined,
                                          size: 15),
                                      onPressed: _nextMonth,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedDate = DateTime.now();
                                          _fetchAttendanceData(selectedslotID!);
                                        });
                                      },
                                      child: const Text(
                                        'Today',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            color: Color(0xFF48116A)),
                                      ),
                                    ),
                                  ],
                                ),

                                // Day Headers
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: weekdays
                                        .map((day) => Text(day,
                                            style: const TextStyle(
                                                color: Color(0xFF48116A),
                                                fontWeight: FontWeight.bold)))
                                        .toList(),
                                  ),
                                ),

                                // Calendar Dates (Using SizedBox for dynamic height)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    int totalRows =
                                        ((_startingWeekday + _daysInMonth) / 7)
                                            .ceil();
                                    double rowHeight =
                                        50; // Adjust row height as needed
                                    double totalHeight = totalRows * rowHeight;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: SizedBox(
                                        height:
                                            totalHeight, // Dynamically calculated height
                                        child: GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(), // Prevent inner scrolling
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 7,
                                            childAspectRatio: 1.2,
                                            mainAxisExtent:
                                                50, // Height of each date box
                                          ),
                                          itemCount:
                                              _startingWeekday + _daysInMonth,
                                          itemBuilder: (context, index) {
                                            if (index < _startingWeekday) {
                                              return const SizedBox.shrink();
                                            }

                                            int day =
                                                index - _startingWeekday + 1;
                                            bool isToday =
                                                day == DateTime.now().day &&
                                                    _selectedDate.month ==
                                                        DateTime.now().month &&
                                                    _selectedDate.year ==
                                                        DateTime.now().year;

                                            String status = _attendanceData[day]
                                                    ?['status'] ??
                                                "no_data";
                                            String? id =
                                                _attendanceData[day]?['id'];
                                            String? date =
                                                _attendanceData[day]?['date'];

                                            return GestureDetector(
                                              onTap: () {
                                                if (id != null) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: Text(
                                                          "Update Attendance for $day"),
                                                      content: DropdownButton<
                                                          String>(
                                                        value: status,
                                                        items: const [
                                                          DropdownMenuItem(
                                                              value: 'present',
                                                              child: Text(
                                                                  'Present')),
                                                          DropdownMenuItem(
                                                              value: 'absent',
                                                              child: Text(
                                                                  'Absent')),
                                                        ],
                                                        onChanged: (newStatus) {
                                                          if (newStatus ==
                                                              'absent') {
                                                            // Close dialog before API call
                                                            try {
                                                              markAbsent(
                                                                date: date!,
                                                                slotID: id,
                                                              );
                                                              Navigator.pop(
                                                                  context);
                                                            } catch (e) {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Failed to mark absent: $e');
                                                              Navigator.pop(
                                                                  context);
                                                            }
                                                          } else if (newStatus ==
                                                              'present') {
                                                            try {
                                                              markPresent(
                                                                date: date!,
                                                                slotID: id,
                                                              );
                                                              Navigator.pop(
                                                                  context);
                                                            } catch (e) {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Failed to mark present: $e');
                                                              Navigator.pop(
                                                                  context);
                                                            }
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            "No ID found for this date!")),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: status == "present"
                                                      ? Colors.green
                                                      : status == "absent"
                                                          ? Colors.red
                                                          : Colors.grey[400],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isToday
                                                        ? const Color(
                                                            0xFF48116A)
                                                        : Colors.white,
                                                    width: isToday ? 3 : 0,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$day',
                                                    style: TextStyle(
                                                        color:
                                                            status == "no_data"
                                                                ? Colors.black
                                                                : Colors.white),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Attendance Summary Section
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              _buildSummaryCard('Present',
                                  _summaryData['present'], Colors.green),
                              _buildSummaryCard(
                                  'Absent', _summaryData['absent'], Colors.red),
                              _buildSummaryCard(
                                  'Holiday',
                                  _summaryData['No class'],
                                  Colors.grey.shade400),
                              _buildSummaryCard(
                                  'Total Classes Taken',
                                  _summaryData['total_classes_taken'],
                                  Colors.yellow),
                            ],
                          ),
                        ),
                      ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 15, top: 5, right: 15, bottom: 10),
                          child: _buildSlotList(),
                        ),
                        // Calendar Section
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 15, bottom: 8, right: 20),
                          child: Container(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            width: 380,
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize:
                                  MainAxisSize.min, // Allow dynamic height
                              children: [
                                // Calendar Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.arrow_back_ios_outlined,
                                          size: 15),
                                      onPressed: _prevMonth,
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          _navigateToYearMonthPicker(context),
                                      child: Text(_monthYearString,
                                          style: const TextStyle(fontSize: 17)),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.arrow_forward_ios_outlined,
                                          size: 15),
                                      onPressed: _nextMonth,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedDate = DateTime.now();
                                          _fetchAttendanceData(selectedslotID!);
                                        });
                                      },
                                      child: const Text(
                                        'Today',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            color: Color(0xFF48116A)),
                                      ),
                                    ),
                                  ],
                                ),

                                // Day Headers
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: weekdays
                                        .map((day) => Text(day,
                                            style: const TextStyle(
                                                color: Color(0xFF48116A),
                                                fontWeight: FontWeight.bold)))
                                        .toList(),
                                  ),
                                ),

                                // Calendar Dates (Using SizedBox for dynamic height)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    int totalRows =
                                        ((_startingWeekday + _daysInMonth) / 7)
                                            .ceil();
                                    double rowHeight =
                                        50; // Adjust row height as needed
                                    double totalHeight = totalRows * rowHeight;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: SizedBox(
                                        height:
                                            totalHeight, // Dynamically calculated height
                                        child: GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(), // Prevent inner scrolling
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 7,
                                            childAspectRatio: 1.2,
                                            mainAxisExtent:
                                                50, // Height of each date box
                                          ),
                                          itemCount:
                                              _startingWeekday + _daysInMonth,
                                          itemBuilder: (context, index) {
                                            if (index < _startingWeekday) {
                                              return const SizedBox.shrink();
                                            }

                                            int day =
                                                index - _startingWeekday + 1;
                                            bool isToday =
                                                day == DateTime.now().day &&
                                                    _selectedDate.month ==
                                                        DateTime.now().month &&
                                                    _selectedDate.year ==
                                                        DateTime.now().year;

                                            String status = _attendanceData[day]
                                                    ?['status'] ??
                                                "no_data";
                                            String? id =
                                                _attendanceData[day]?['id'];
                                            String? date =
                                                _attendanceData[day]?['date'];

                                            return GestureDetector(
                                              onTap: () {
                                                if (id != null) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: Text(
                                                          "Update Attendance for $day"),
                                                      content: DropdownButton<
                                                          String>(
                                                        value: status,
                                                        items: const [
                                                          DropdownMenuItem(
                                                              value: 'present',
                                                              child: Text(
                                                                  'Present')),
                                                          DropdownMenuItem(
                                                              value: 'absent',
                                                              child: Text(
                                                                  'Absent')),
                                                        ],
                                                        onChanged: (newStatus) {
                                                          if (newStatus ==
                                                              'absent') {
                                                            // Close dialog before API call
                                                            try {
                                                              markAbsent(
                                                                date: date!,
                                                                slotID: id,
                                                              );
                                                              Navigator.pop(
                                                                  context);
                                                            } catch (e) {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Failed to mark absent: $e');
                                                              Navigator.pop(
                                                                  context);
                                                            }
                                                          } else if (newStatus ==
                                                              'present') {
                                                            try {
                                                              markPresent(
                                                                date: date!,
                                                                slotID: id,
                                                              );
                                                              Navigator.pop(
                                                                  context);
                                                            } catch (e) {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Failed to mark present: $e');
                                                              Navigator.pop(
                                                                  context);
                                                            }
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            "No ID found for this date!")),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: status == "present"
                                                      ? Colors.green
                                                      : status == "absent"
                                                          ? Colors.red
                                                          : Colors.grey[400],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isToday
                                                        ? const Color(
                                                            0xFF48116A)
                                                        : Colors.white,
                                                    width: isToday ? 3 : 0,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$day',
                                                    style: TextStyle(
                                                        color:
                                                            status == "no_data"
                                                                ? Colors.black
                                                                : Colors.white),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Attendance Summary Section
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              _buildSummaryCard('Present',
                                  _summaryData['present'], Colors.green),
                              _buildSummaryCard(
                                  'Absent', _summaryData['absent'], Colors.red),
                              _buildSummaryCard(
                                  'Holiday',
                                  _summaryData['No class'],
                                  Colors.grey.shade400),
                              _buildSummaryCard(
                                  'Total Classes Taken',
                                  _summaryData['total_classes_taken'],
                                  Colors.yellow),
                            ],
                          ),
                        ),
                      ])));
  }

  Widget _buildSlotList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(slots.length, (index) {
          bool isSelected = selectedSlotIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedSlotIndex = index;
                selectedslotID = slots[index]['slotID']!; // Get slotID
                _fetchAttendanceData(selectedslotID!); // Pass slotID
                _updateSummary();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    '${slots[index]['courseName']!}, ', // Display slot name
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    slots[index]['timeSlot']!, // Display slot name
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    int? count,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Container(
        width: 400,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    textAlign: TextAlign.justify,
                    count == null ? '0' : ' $count ',
                    style: const TextStyle(color: Colors.black54, fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                ' $title',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YearMonthPicker extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;

  const YearMonthPicker(
      {super.key, required this.selectedYear, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final List<int> years =
        List.generate(currentYear - 2000 + 1, (index) => 2000 + index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Year and Month'),
      ),
      body: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          int year = years[index];
          return ExpansionTile(
            title: Text('$year'),
            children: List.generate(12, (monthIndex) {
              return ListTile(
                title: Text('Month: ${monthIndex + 1}'),
                onTap: () {
                  Navigator.pop(
                      context, {'year': year, 'month': monthIndex + 1});
                },
              );
            }),
          );
        },
      ),
    );
  }
}
