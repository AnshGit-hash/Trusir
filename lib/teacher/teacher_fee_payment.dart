import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:trusir/teacher/teacher_wallet.dart';

class Fees {
  final String paymentType;
  final String transactionId;
  final String paymentMethod;
  final String amount;
  final String date;
  final String time;

  Fees({
    required this.paymentType,
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
    required this.date,
    required this.time,
  });

  factory Fees.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] as String? ?? '';
    final dateTime = DateTime.tryParse(createdAt) ?? DateTime.now();

    final formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
    final formattedTime = DateFormat('h:mm a').format(dateTime);

    return Fees(
      paymentType: json['transactionType'] ?? '',
      transactionId: json['transactionID'] ?? '',
      paymentMethod: json['transactionName'] ?? '',
      amount: json['amount'] ?? '0',
      date: formattedDate,
      time: formattedTime,
    );
  }
}

class HoldAmount {
  final String id;
  final String date;
  final String amount;
  final String time;

  HoldAmount({
    required this.id,
    required this.date,
    required this.amount,
    required this.time,
  });

  factory HoldAmount.fromJson(Map<String, dynamic> json) {
    final dateTime = DateTime.tryParse(json['created_at'] ?? '');
    final formattedDate =
        dateTime != null ? DateFormat('dd-MM-yyyy').format(dateTime) : '';
    final formattedTime =
        dateTime != null ? DateFormat('h:mm a').format(dateTime) : '';

    String amountText = json['amount_added_to_teacher'] ?? '';
    String holdAmount = '0';
    RegExp regExp = RegExp(r'Teacher-Fee:\(Hold\) (\d+\.?\d*)');
    Match? match = regExp.firstMatch(amountText);
    if (match != null && match.groupCount >= 1) {
      holdAmount = match.group(1) ?? '0';
    }

    return HoldAmount(
      id: json['id'].toString(),
      date: formattedDate,
      amount: holdAmount,
      time: formattedTime,
    );
  }
}

class WithdrawalRequest {
  final String id;
  final String amount;
  final String date;
  final String time;
  final String status;

  WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.date,
    required this.time,
    required this.status,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    final dateTime = DateTime.tryParse(json['created_at'] ?? '');
    final formattedDate =
        dateTime != null ? DateFormat('dd-MM-yyyy').format(dateTime) : '';
    final formattedTime =
        dateTime != null ? DateFormat('h:mm a').format(dateTime) : '';

    return WithdrawalRequest(
      id: json['id'].toString(),
      amount: json['amount'] ?? '0',
      date: formattedDate,
      time: formattedTime,
      status: json['status'] ?? 'pending',
    );
  }
}

class TeacherFeePaymentScreen extends StatefulWidget {
  final List<String> slots;
  const TeacherFeePaymentScreen({super.key, required this.slots});

  @override
  State<TeacherFeePaymentScreen> createState() =>
      _TeacherFeePaymentScreenState();
}

class _TeacherFeePaymentScreenState extends State<TeacherFeePaymentScreen> {
  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  List<Fees> feepayment = [];
  List<HoldAmount> holdAmounts = [];
  List<WithdrawalRequest> withdrawalRequests = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMore = true;
  double balance = 0;
  bool isLoadingHoldAmounts = true;
  bool isLoadingWithdrawals = true;

  final apiBase = '$baseUrl/get-fee-payment-info/';

  Future<double> fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/get-user/$userID'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          balance = double.parse(data['balance']);
        });
        return balance;
      } else {
        throw Exception('Failed to load balance');
      }
    } catch (e) {
      print('Error: $e');
      return 0;
    }
  }

  Future<void> fetchHoldAmounts() async {
    try {
      // Fetch data for each slot ID sequentially
      for (String slotID in widget.slots) {
        final response =
            await http.get(Uri.parse('$baseUrl/view-slot-attendance/$slotID'));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            holdAmounts = data
                .map((json) => HoldAmount.fromJson(json))
                .where((hold) => hold.amount != '0')
                .toList();
            isLoadingHoldAmounts = false;
          });
        } else {
          print(
              'Failed to fetch data for slot $slotID: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      setState(() {
        isLoadingHoldAmounts = false;
      });
      throw Exception(
          'Failed to load hold amounts'); // Return empty list on error
    }
  }

  Future<void> fetchWithdrawalRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherID = prefs.getString('id');
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/withdraw-requests/$teacherID?data_per_page=10&page=1'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> requests = data['data'] ?? [];
        setState(() {
          withdrawalRequests =
              requests.map((json) => WithdrawalRequest.fromJson(json)).toList();
          isLoadingWithdrawals = false;
        });
      } else {
        throw Exception('Failed to load withdrawal requests');
      }
    } catch (e) {
      print('Error fetching withdrawal requests: $e');
      setState(() {
        isLoadingWithdrawals = false;
      });
    }
  }

  Future<void> fetchFeeDetails({int page = 1}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    final url = '$apiBase$userID?page=$page&data_per_page=10';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        if (page == 1) {
          feepayment = data
              .map((json) => Fees.fromJson(json))
              .where((fee) =>
                  fee.paymentMethod != 'ByAdmin' &&
                  fee.paymentMethod != 'By Admin')
              .toList();
        } else {
          feepayment.addAll(data.map((json) => Fees.fromJson(json)).where(
              (fee) =>
                  fee.paymentMethod != 'ByAdmin' &&
                  fee.paymentMethod != 'By Admin'));
        }

        // Remove the problematic sorting code that uses firstWhere
        // Replace it with a safer sorting method if needed
        feepayment.sort((a, b) {
          // Use the date/time you already have in the Fees object
          final dateA =
              DateFormat('dd-MM-yyyy h:mm a').tryParse('${a.date} ${a.time}');
          final dateB =
              DateFormat('dd-MM-yyyy h:mm a').tryParse('${b.date} ${b.time}');

          return (dateB ?? DateTime(0)).compareTo(dateA ?? DateTime(0));
        });

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
      throw Exception('Failed to load fees');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFeeDetails();
    fetchBalance();
    fetchHoldAmounts();
    fetchWithdrawalRequests();
  }

  final List<Color> cardColors = [
    Colors.blue.shade100,
    Colors.yellow.shade100,
    Colors.pink.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
  ];

  final List<Color> holdCardColors = [
    Colors.orange.shade100,
    Colors.cyan.shade100,
    Colors.lime.shade100,
    Colors.indigo.shade100,
    Colors.teal.shade100,
  ];

  final List<Color> withdrawalCardColors = [
    Colors.amber.shade100,
    Colors.deepOrange.shade100,
    Colors.brown.shade100,
    Colors.blueGrey.shade100,
    Colors.deepPurple.shade100,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/back_button.png', height: 50)),
              const SizedBox(width: 10),
              const Text(
                'Fee Payment',
                style: TextStyle(
                  color: Color(0xFF48116A),
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.08,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherWalletPage(
                    withdrawRequest: withdrawalRequests,
                    holdAmount: holdAmounts,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Color.fromARGB(255, 28, 37, 136),
                ),
                Text(
                  '₹ $balance',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ]),
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;

          return isLoading || isLoadingHoldAmounts || isLoadingWithdrawals
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: isWideScreen
                      ? Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCurrentMonthCard(
                                    MediaQuery.of(context).size.width * 0.4,
                                    isWideScreen),
                              ],
                            ),
                            const SizedBox(width: 40),
                            feepayment.isEmpty &&
                                    holdAmounts.isEmpty &&
                                    withdrawalRequests.isEmpty
                                ? const Padding(
                                    padding:
                                        EdgeInsets.only(top: 20.0, left: 23),
                                    child: Center(
                                        child: Text(
                                            'No Transaction history available')),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 10),
                                        if (withdrawalRequests.isNotEmpty) ...[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                top: 20.0, left: 23),
                                            child: Text(
                                              'Withdrawal Requests',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          ...withdrawalRequests
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            int index = entry.key;
                                            WithdrawalRequest request =
                                                entry.value;
                                            Color cardColor =
                                                withdrawalCardColors[index %
                                                    withdrawalCardColors
                                                        .length];
                                            return _buildWithdrawalCard(
                                                cardColor, request, index);
                                          }),
                                        ],
                                        if (holdAmounts.isNotEmpty) ...[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                top: 20.0, left: 23),
                                            child: Text(
                                              'Amount on Hold',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          ...holdAmounts
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            int index = entry.key;
                                            HoldAmount hold = entry.value;
                                            Color cardColor = holdCardColors[
                                                index % holdCardColors.length];
                                            return _buildHoldCard(
                                                cardColor, hold, index);
                                          }),
                                        ],
                                        if (feepayment.isNotEmpty) ...[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                top: 20.0, left: 23),
                                            child: Text(
                                              'Previous month',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          ...feepayment
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            int index = entry.key;
                                            Fees payment = entry.value;
                                            Color cardColor = cardColors[
                                                index % cardColors.length];
                                            return _buildFeeCard(
                                                cardColor, payment, index);
                                          }),
                                        ],
                                        if (hasMore)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: isLoadingMore
                                                ? const CircularProgressIndicator()
                                                : TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        isLoadingMore = true;
                                                        currentPage++;
                                                      });
                                                      fetchFeeDetails(
                                                          page: currentPage);
                                                    },
                                                    child: const Text(
                                                        'Load More...'),
                                                  ),
                                          ),
                                      ],
                                    ),
                                  ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              _buildCurrentMonthCard(
                                  MediaQuery.of(context).size.width * 0.9,
                                  isWideScreen),
                              if (withdrawalRequests.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Center(
                                    child: Text(
                                      'Withdrawal Requests',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ...withdrawalRequests
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key;
                                  WithdrawalRequest request = entry.value;
                                  Color cardColor = withdrawalCardColors[
                                      index % withdrawalCardColors.length];
                                  return _buildWithdrawalCard(
                                      cardColor, request, index);
                                }),
                              ],
                              if (holdAmounts.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Center(
                                    child: Text(
                                      'Amount on Hold',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ...holdAmounts.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  HoldAmount hold = entry.value;
                                  Color cardColor = holdCardColors[
                                      index % holdCardColors.length];
                                  return _buildHoldCard(cardColor, hold, index);
                                }),
                              ],
                              if (feepayment.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Center(
                                    child: Text(
                                      'Previous month',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ...feepayment.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Fees payment = entry.value;
                                  Color cardColor =
                                      cardColors[index % cardColors.length];
                                  return _buildFeeCard(
                                      cardColor, payment, index);
                                }),
                              ],
                              if (feepayment.isEmpty &&
                                  holdAmounts.isEmpty &&
                                  withdrawalRequests.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Center(
                                      child: Text(
                                          'No Transaction history available')),
                                ),
                              if (hasMore)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : TextButton(
                                          onPressed: () {
                                            setState(() {
                                              isLoadingMore = true;
                                              currentPage++;
                                            });
                                            fetchFeeDetails(page: currentPage);
                                          },
                                          child: const Text('Load More...'),
                                        ),
                                ),
                            ],
                          ),
                        ),
                );
        }),
      ),
    );
  }

  Widget _buildWithdrawalCard(
      Color cardColor, WithdrawalRequest request, int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 15),
      child: Container(
        width: 386,
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Withdrawal Requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'ID: ${request.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Status: ${request.status}',
                        style: TextStyle(
                          fontSize: 14,
                          color: request.status == 'pending'
                              ? Colors.orange
                              : request.status == 'approved'
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    children: [
                      Text(
                        '₹ ${request.amount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        request.date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        request.time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldCard(Color cardColor, HoldAmount hold, int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 15),
      child: Container(
        width: 386,
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10),
          child: Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 5.0, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount on Hold',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Pending Payment',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Wallet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    children: [
                      Text(
                        '₹ ${hold.amount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        hold.date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        hold.time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeCard(Color cardColor, Fees payment, int index) {
    String displayedTransactionId = payment.transactionId.contains(',')
        ? payment.transactionId.split(',').first.trim()
        : payment.transactionId.trim();

    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 15),
      child: Container(
        width: 386,
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.paymentType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        displayedTransactionId,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        payment.paymentMethod,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    children: [
                      Text(
                        '₹ ${payment.amount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        payment.date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        payment.time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMonthCard(double width, bool isLargeScreen) {
    DateTime now = DateTime.now();
    DateTime firstOfMonth = DateTime(now.year, now.month, 1);
    String formattedStart = DateFormat('d MMM yyyy').format(firstOfMonth);
    return Container(
      width: width,
      height: isLargeScreen ? 150 : 110,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF48116A), Color(0xFFC22054)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color.fromARGB(255, 160, 40, 176).withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 3,
              offset: const Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Current Month',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$formattedStart - Today',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                const Text(
                  'Total No. of Classes: 09',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/money@3x.png',
            width: 130,
            height: 130,
          ),
        ],
      ),
    );
  }
}
