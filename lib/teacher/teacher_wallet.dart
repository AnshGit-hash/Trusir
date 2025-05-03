import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/common/phonepe_payment.dart';
import 'package:trusir/student/payment__status_popup.dart';
import 'package:trusir/teacher/teacher_fee_payment.dart';
import 'package:trusir/teacher/teacher_main_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherWalletPage extends StatefulWidget {
  final List<HoldAmount> holdAmount;
  final List<WithdrawalRequest> withdrawRequest;
  const TeacherWalletPage(
      {super.key, required this.holdAmount, required this.withdrawRequest});

  @override
  State<TeacherWalletPage> createState() => _TeacherWalletPageState();
}

class _TeacherWalletPageState extends State<TeacherWalletPage> {
  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
    return formattedDate;
  }

  double balance = 0;
  double hold = 0;
  List<Map<String, dynamic>> walletTransactions = [];
  PaymentService paymentService = PaymentService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchBalance();
    fetchWalletTransactions();
    paymentService.initPhonePeSdk();
  }

  Future<double> fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userID');
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/get-user/$userID'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          balance = double.parse(data['balance']);
          hold = double.parse(data['holdAmount']);
          prefs.setString('wallet_balance', '$balance');
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

  Future<List<Map<String, dynamic>>> fetchWalletTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    final response =
        await http.get(Uri.parse('$baseUrl/get-fee-payment-info/$userID'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      List<Map<String, dynamic>> walletTransactions = data
          .where((transaction) =>
              transaction['transactionName'] == 'WALLET' ||
              transaction['transactionName'] == 'ByAdmin')
          .map((transaction) => transaction as Map<String, dynamic>)
          .toList();

      walletTransactions.sort((a, b) {
        DateTime dateA = DateTime.parse(a['created_at']);
        DateTime dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        this.walletTransactions = walletTransactions;
      });

      return walletTransactions;
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<void> submitWithdrawalRequest(String amount) async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userID = prefs.getString('id');

      final response = await http.get(
        Uri.parse('$baseUrl/withdraw-request/$userID/$amount'),
      );

      if (response.statusCode == 200) {
        showCustomToast(context, 'Withdrawal request submitted successfully');
        fetchBalance(); // Refresh balance after successful withdrawal
      } else if (response.statusCode == 400) {
        Map<String, dynamic> data = jsonDecode(response.body);
        showCustomToast(
            context, 'Failed to submit withdrawal request: ${data['message']}');
      } else {
        showCustomToast(context,
            'Failed to submit withdrawal request: ${response.statusCode}');
      }
    } catch (e) {
      showCustomToast(context, 'Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String merchantTransactionID = '';
  bool paymentstatus = false;
  String? addMoneyamount;

  String body = "";
  String checksum = "";
  String? userID;
  String? phone;
  TextEditingController amountController = TextEditingController();
  TextEditingController promoController = TextEditingController();
  String transactionType = '';

  void checkStatus() async {
    String url =
        "https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/status/$merchantId/$merchantTransactionID";

    String concat = "/pg/v1/status/$merchantId/$merchantTransactionID$saltKey";

    var bytes = utf8.encode(concat);

    var digest = sha256.convert(bytes).toString();

    String xVerify = "$digest###$saltIndex";

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "X-VERIFY": xVerify,
      "X-MERCHANT-ID": merchantId,
    };

    try {
      await Future.delayed(const Duration(seconds: 5));

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        Navigator.pop(context);
        if (responseData["success"] &&
            responseData["code"] == "PAYMENT_SUCCESS" &&
            responseData["data"]["state"] == "COMPLETED") {
          int adjustedAmount = (responseData["data"]['amount'] / 100).toInt();

          setState(() {
            transactionType =
                responseData["data"]["paymentInstrument"]["type"] == 'CARD'
                    ? responseData["data"]["paymentInstrument"]["cardType"]
                    : responseData["data"]["paymentInstrument"]["type"];
            paymentstatus = true;
          });
          if (paymentstatus) {
            paymentService.addWalletBalance(
                context, addMoneyamount ?? '0', userID);
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PaymentPopUpPage(
                      isWallet: true,
                      adjustedAmount: double.parse('$adjustedAmount'),
                      isSuccess: paymentstatus,
                      transactionID: merchantTransactionID,
                      transactionType: transactionType)),
            );
          }
        } else {
          setState(() {
            paymentstatus = false;
          });
        }
      } else {
        setState(() {
          paymentstatus = false;
        });
        throw Exception("Failed to fetch payment status");
      }
    } catch (e) {
      setState(() {
        paymentstatus = false;
      });
    }
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(
                    "Processing payment, \nplease wait...\nPlease don't press back"),
              ],
            ),
          ),
        );
      },
    );
  }

  void paymentstatusnavigation() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PaymentPopUpPage(
              isWallet: true,
              adjustedAmount: double.parse(addMoneyamount ?? '0'),
              isSuccess: paymentstatus,
              transactionID: merchantTransactionID,
              transactionType: transactionType)),
    );
  }

  getChecksum(int am) {
    final reqData = {
      "merchantId": merchantId,
      "merchantTransactionId": merchantTransactionID,
      "merchantUserId": userID,
      "amount": am,
      "callbackUrl": callback,
      "mobileNumber": "+91$phone",
      "paymentInstrument": {"type": "PAY_PAGE"}
    };
    String base64body = base64.encode(utf8.encode(json.encode(reqData)));
    checksum =
        '${sha256.convert(utf8.encode(base64body + apiEndPoint + saltKey)).toString()}###$saltIndex';

    return base64body;
  }

  Future<void> _launchWhatsApp(String phoneNumber, String message) async {
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      final bool launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      print("Error launching WhatsApp: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[50],
        title: const Text(
          "My Wallet",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Available Balance",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          '₹ $balance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          "  (Amount on Hold : ₹ ${hold.abs().toStringAsFixed(2)})",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Withdraw Amount",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 16),
                                      Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              validator: (value) =>
                                                  value!.isEmpty
                                                      ? "Required"
                                                      : null,
                                              controller: amountController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: "Amount",
                                                prefixIcon: const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 25.0, top: 11),
                                                  child: Text("₹",
                                                      style: TextStyle(
                                                          fontSize: 18)),
                                                ),
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: isLoading
                                                    ? null
                                                    : () async {
                                                        if (_formKey
                                                            .currentState!
                                                            .validate()) {
                                                          await submitWithdrawalRequest(
                                                              amountController
                                                                  .text);
                                                          Navigator.pop(
                                                              context);
                                                        }
                                                      },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                                  textStyle: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  elevation: 6,
                                                ),
                                                child: isLoading
                                                    ? const CircularProgressIndicator(
                                                        color: Colors.white,
                                                      )
                                                    : const Text("Submit"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: _buildActionButton(Icons.add, "Withdraw")),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WalletTransactions(
                                      transactions: walletTransactions,
                                      withdrawRequest: widget.withdrawRequest,
                                      holdAmount: widget.holdAmount)),
                            );
                          },
                          child: _buildActionButton(Icons.history, "History")),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const Rewards(transactions: [])),
                            );
                          },
                          child: _buildActionButton(
                              Icons.card_giftcard, "Rewards")),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Actions Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeacherMainScreen(
                              index: 1,
                            ),
                          ),
                          (Route<dynamic> route) => false,
                        ),
                        child: _buildQuickAction(
                            Icons.school, "Student Courses", Colors.blue),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Rewards",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: "Poppins"),
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: promoController,
                                            decoration: InputDecoration(
                                              hintText: "Enter Promo",
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 40.0, right: 40),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                                  textStyle: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  elevation: 6,
                                                  shadowColor:
                                                      Colors.deepPurpleAccent,
                                                ),
                                                child: const Text(
                                                  "Confirm",
                                                  style: TextStyle(
                                                      fontFamily: "Poppins"),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ));
                        },
                        child: _buildQuickAction(
                            Icons.card_giftcard, "Redeem", Colors.orange),
                      ),
                      GestureDetector(
                          onTap: () {
                            _launchWhatsApp(
                                '+919801458766', 'Transactions Sharing');
                          },
                          child: _buildQuickAction(
                              Icons.share, "Share", Colors.green)),
                    ],
                  ),
                ],
              ),
            ),

            // Recent Transactions
            SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.withdrawRequest.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Withdrawal Requests",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.withdrawRequest.map((request) {
                            return _buildWithdrawalItem(
                              "Withdrawal Request",
                              double.tryParse(request.amount) ?? 0.0,
                              request.date,
                              request.status,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  if (widget.holdAmount.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Amount on Hold",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.holdAmount.map((hold) {
                            return _buildHoldItem(
                              "Amount on Hold",
                              double.tryParse(hold.amount) ?? 0.0,
                              hold.date,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: walletTransactions.isEmpty
                        ? const Center(
                            child: Text("No Wallet Transactions Found"))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Wallet Transactions",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...walletTransactions.map((transaction) {
                                return _buildTransactionItem(
                                  transaction["transactionType"] ??
                                      "Unknown Transaction",
                                  double.tryParse(
                                          transaction["amount"] ?? "0.0") ??
                                      0.0,
                                  formatDate(transaction["created_at"]),
                                );
                              }),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalItem(
      String description, double amount, String date, String status) {
    Color statusColor = Colors.orange;
    if (status == 'approved') {
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.currency_rupee_sharp,
              color: Colors.amber,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "-₹${amount.abs().toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoldItem(String description, double amount, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_clock,
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹${amount.abs().toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String description, double amount, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amount > 0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              amount > 0 ? Icons.add : Icons.remove,
              color: amount > 0 ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${amount > 0 ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: amount > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class WalletTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final List<WithdrawalRequest> withdrawRequest;
  final List<HoldAmount> holdAmount;

  const WalletTransactions({
    super.key,
    required this.transactions,
    required this.withdrawRequest,
    required this.holdAmount,
  });

  @override
  Widget build(BuildContext context) {
    String formatDate(String dateString) {
      DateTime dateTime = DateTime.parse(dateString);
      String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
      return formattedDate;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[50],
        title: const Text(
          "Wallet Transactions",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (withdrawRequest.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Withdrawal Requests",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...withdrawRequest.map((request) {
                      return _buildWithdrawalItem(
                        "Withdrawal Request",
                        double.tryParse(request.amount) ?? 0.0,
                        request.date,
                        request.status,
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (holdAmount.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Amount on Hold",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...holdAmount.map((hold) {
                      return _buildHoldItem(
                        "Amount on Hold",
                        double.tryParse(hold.amount) ?? 0.0,
                        hold.date,
                      );
                    }),
                  ],
                ),
              ),
            ],
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: transactions.isEmpty
                  ? const Center(child: Text("No Wallet Transactions Found"))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Wallet Transactions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...transactions.map((transaction) {
                          return _buildTransactionItem(
                            transaction["transactionType"] ??
                                "Unknown Transaction",
                            double.tryParse(transaction["amount"] ?? "0.0") ??
                                0.0,
                            formatDate(transaction["created_at"]),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalItem(
      String description, double amount, String date, String status) {
    Color statusColor = Colors.orange;
    if (status == 'approved') {
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.money_off,
              color: Colors.amber,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "-₹${amount.abs().toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoldItem(String description, double amount, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_clock,
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹${amount.abs().toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String description, double amount, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amount > 0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              amount > 0 ? Icons.add : Icons.remove,
              color: amount > 0 ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${amount > 0 ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: amount > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class Rewards extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const Rewards({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    String formatDate(String dateString) {
      DateTime dateTime = DateTime.parse(dateString);
      String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
      return formattedDate;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[50],
        title: const Text(
          "Rewards",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: transactions.isEmpty
            ? const Center(child: Text("No Rewards Transactions Found"))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: transactions.map((transaction) {
                  return _buildTransactionItem(
                    transaction["transactionType"] ?? "Unknown Transaction",
                    double.tryParse(transaction["amount"] ?? "0.0") ?? 0.0,
                    formatDate(transaction["created_at"]),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildTransactionItem(String description, double amount, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amount > 0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              amount > 0 ? Icons.add : Icons.remove,
              color: amount > 0 ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${amount > 0 ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              color: amount > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
