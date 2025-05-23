import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:trusir/student/wallet.dart';

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
    final createdAt = json['created_at'] ?? '';
    final dateTime = DateTime.tryParse(createdAt);

    final formattedDate =
        dateTime != null ? DateFormat('dd-MM-yyyy').format(dateTime) : '';
    final formattedTime =
        dateTime != null ? DateFormat('h:mm a').format(dateTime) : '';

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

class FeePaymentScreen extends StatefulWidget {
  const FeePaymentScreen({super.key});

  @override
  State<FeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends State<FeePaymentScreen> {
  List<Fees> feepayment = [];
  bool isLoading = true;
  double balance = 0;

  final apiBase = '$baseUrl/get-fee-payment-info/';

  Future<double> fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/get-user/$userID'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(double.parse(data['balance']));
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

  Future<void> fetchFeeDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    final url = '$apiBase$userID';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        feepayment = data
            .map((json) => Fees.fromJson(json))
            .where((fee) =>
                fee.paymentMethod != 'ByAdmin' &&
                fee.paymentMethod != 'By Admin')
            .toList();
      });

      // Sort transactions by created_at in descending order (latest first)
      feepayment.sort((a, b) {
        DateTime dateA = DateTime.tryParse(jsonDecode(response.body).firstWhere(
                (e) => e['transactionID'] == a.transactionId)['created_at']) ??
            DateTime(0);
        DateTime dateB = DateTime.tryParse(jsonDecode(response.body).firstWhere(
                (e) => e['transactionID'] == b.transactionId)['created_at']) ??
            DateTime(0);
        return dateB.compareTo(dateA);
      });

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load fees');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFeeDetails();
    fetchBalance();
  }

  final List<Color> cardColors = [
    Colors.blue.shade100,
    Colors.yellow.shade100,
    Colors.pink.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
  ];

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
                  builder: (context) => const WalletPage(),
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

          return isLoading
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
                            feepayment.isEmpty
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

                                          String displayedTransactionId =
                                              payment.transactionId.contains(
                                                      ',')
                                                  ? payment.transactionId
                                                      .split(',')
                                                      .first
                                                      .trim()
                                                  : payment.transactionId
                                                      .trim();

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                left: 5, right: 5, bottom: 15),
                                            child: Container(
                                              width: 386,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 10.0, right: 10),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 5.0,
                                                                top: 10),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              payment
                                                                  .paymentType,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                            Text(
                                                              displayedTransactionId,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 18),
                                                            Text(
                                                              payment
                                                                  .paymentMethod,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 10.0),
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              '₹ ${payment.amount}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            Text(
                                                              payment.date,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 18),
                                                            Text(
                                                              payment.time,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
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
                                        }),
                                      ],
                                    ),
                                  ),
                          ],
                        )
                      : Stack(
                          children: [
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 10),
                                  _buildCurrentMonthCard(
                                      MediaQuery.of(context).size.width * 0.9,
                                      isWideScreen),
                                  feepayment.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.only(top: 15),
                                          child: Center(
                                              child: Text(
                                                  'No Transaction history available')),
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.only(
                                            top: 15.0,
                                          ),
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
                                    String displayedTransactionId =
                                        payment.transactionId.contains(',')
                                            ? payment.transactionId
                                                .split(',')
                                                .first
                                                .trim()
                                            : payment.transactionId.trim();

                                    Color cardColor =
                                        cardColors[index % cardColors.length];

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5, bottom: 15),
                                      child: Container(
                                        width: 386,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 10.0, right: 10),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 5.0, top: 10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        payment.paymentType,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                                      const SizedBox(
                                                          height: 18),
                                                      Text(
                                                        payment.paymentMethod,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 10.0),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        '₹ ${payment.amount}',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        payment.date,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 18),
                                                      Text(
                                                        payment.time,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                );
        }),
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
