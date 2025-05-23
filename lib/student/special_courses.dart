import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/common/phonepe_payment.dart';
import 'package:trusir/student/course.dart';
import 'package:trusir/student/payment__status_popup.dart';
import 'package:trusir/student/payment_method.dart';

class SpecialCourses extends StatefulWidget {
  final List<Course> courses;
  const SpecialCourses({super.key, required this.courses});

  @override
  State<SpecialCourses> createState() => _SpecialCoursesState();
}

class _SpecialCoursesState extends State<SpecialCourses> {
  bool isWeb = false;

  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600;
    return widget.courses.isEmpty
        ? const SizedBox()
        : isWeb
            ? GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisExtent: 560),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: widget.courses.length,
                itemBuilder: (context, index) {
                  final course = widget.courses[index];
                  return CourseCard(
                    course: course,
                  );
                },
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: widget.courses.length,
                itemBuilder: (context, index) {
                  final course = widget.courses[index];
                  return CourseCard(
                    course: course,
                  );
                },
              );
  }
}

class CourseCard extends StatefulWidget {
  final Course course;
  const CourseCard({super.key, required this.course});

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool isWeb = false;
  final PaymentService paymentService = PaymentService();
  @override
  void initState() {
    super.initState();
    // paymentService.initPhonePeSdk();
    fetchProfileData();
    fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600;
    double discount = 100 -
        int.parse(widget.course.newAmount) /
            int.parse(widget.course.amount) *
            100;

    String formattedDiscount = discount.toStringAsFixed(2);
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isWeb ? 30 : 16, vertical: isWeb ? 15 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 30 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.course.image,
                    width: double.infinity,
                    height: isWeb ? 300 : 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error,
                          size: 40,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Best Seller',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 18 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.course.name,
              style: TextStyle(
                fontSize: isWeb ? 21 : 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.course.subject,
              style: TextStyle(
                fontSize: isWeb ? 18 : 14,
                fontFamily: 'Poppins',
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  '₹${widget.course.newAmount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  '₹${widget.course.amount}', // Placeholder for original price
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  '$formattedDiscount% OFF', // Placeholder for original price
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // widget.course['status'] == 'demo' ||
                //         widget.course['status'] == null
                //     ?
                SizedBox(
                  width: isWeb ? 200 : 142,
                  height: isWeb ? 40 : null,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.3),
                          builder: (BuildContext context) {
                            return PaymentMethod.buildDialog(
                                amount: widget.course.newAmount,
                                name: widget.course.name,
                                balance: '$balance',
                                onPhonePayment: () {
                                  // merchantTransactionID = paymentService
                                  //     .generateUniqueTransactionId(userID!);
                                  // body = getChecksum(
                                  //   int.parse('${widget.course.newAmount}00'),
                                  // ).toString();
                                  // paymentService.startTransaction(
                                  //     body,
                                  //     checksum,
                                  //     checkStatus,
                                  //     showLoadingDialog,
                                  //     paymentstatusnavigation,
                                  //     context);
                                  showCustomToast(context,
                                      'Coming soon Kindly proceed with wallet payment');
                                },
                                onWalletPayment: () {
                                  Navigator.pop(context);
                                  walletPayment(widget.course.newAmount,
                                      widget.course.id);
                                });
                          });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: isWeb ? 200 : 142,
                  height: isWeb ? 40 : null,
                  child: ElevatedButton(
                    onPressed: () {
                      bookDemo();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 225, 143, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Demo',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> bookDemo() async {
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userID');
    // Replace with your API URL
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/book-demo/$userID/${widget.course.id}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showCustomToast(context, data['message']);
        // Convert balance to an integer
      } else {
        throw Exception('Failed to Book Demo');
      }
    } catch (e) {
      print('Error: $e');
      // Return 0 in case of an error
    }
  }

  void walletPayment(String amount, int courseID) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing wallet payment..."),
            ],
          ),
        );
      },
    );

    // Add 2-second delay
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      payviawallet = true;
    });
    if (double.parse(amount) > balance) {
      // bool success =
      //     await paymentService.subWalletBalance(context, '$balance', userID);
      // if (success) {
      //   merchantTransactionID =
      //       paymentService.generateUniqueTransactionId(userID!);
      //   body = getChecksum(
      //     int.parse('${double.parse(amount) - balance}00'),
      //   ).toString();
      //   paymentService.startTransaction(body, checksum, checkStatus,
      //       showLoadingDialog, paymentstatusnavigation);
      // } else {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => PaymentPopUpPage(
      //             isWallet: false,
      //             adjustedAmount: double.parse(amount),
      //             isSuccess: false,
      //             transactionID: 'transactionID',
      //             transactionType: 'WALLET')),
      //   );
      // }
      showCustomToast(
          context, 'Insufficient Balance, Contact Customer Support');
      Navigator.pop(context);
    } else {
      bool success =
          await paymentService.subWalletBalance(context, amount, userID);

      if (success) {
        postTransaction('WALLET', int.parse(amount), transactionType,
            'transactionID', courseID);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PaymentPopUpPage(
                  isWallet: false,
                  adjustedAmount: double.parse(amount),
                  isSuccess: true,
                  transactionID: 'transactionID',
                  transactionType: 'WALLET')),
        );
      } else {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PaymentPopUpPage(
                  isWallet: false,
                  adjustedAmount: double.parse(amount),
                  isSuccess: false,
                  transactionID: 'transactionID',
                  transactionType: 'WALLET')),
        );
      }
    }
  }

  String body = "";
  // Transaction details
  String checksum = "";
  // Obtain this from your backend
  String? userID;
  bool paymentstatus = false;
  String transactionType = '';
  double balance = 0;
  bool payviawallet = false;
  String? phone;

  String merchantTransactionID = '';

  Future<void> fetchProfileData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID');
      phone = prefs.getString('phone_number');
    });
  }

  Future<double> fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userID');
    // Replace with your API URL
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/get-user/$userID'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(double.parse(data['balance']));
        setState(() {
          balance = double.parse(data['balance']);
          prefs.setString('wallet_balance', '$balance');
        });
        return balance; // Convert balance to an integer
      } else {
        throw Exception('Failed to load balance');
      }
    } catch (e) {
      print('Error: $e');
      return 0; // Return 0 in case of an error
    }
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
      // Wait for 30 seconds before making the request
      await Future.delayed(const Duration(seconds: 5));

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        Navigator.pop(context);
        if (responseData["success"] &&
            responseData["code"] == "PAYMENT_SUCCESS" &&
            responseData["data"]["state"] == "COMPLETED") {
          // Payment Success
          int adjustedAmount = (responseData["data"]['amount'] / 100).toInt();

          // Show Success Dialog
          setState(() {
            transactionType =
                responseData["data"]["paymentInstrument"]["type"] == 'CARD'
                    ? responseData["data"]["paymentInstrument"]["cardType"]
                    : responseData["data"]["paymentInstrument"]["type"];
            paymentstatus = true;
          });
          print(paymentstatus);
          if (paymentstatus) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PaymentPopUpPage(
                      isWallet: false,
                      adjustedAmount: double.parse(widget.course.newAmount),
                      isSuccess: paymentstatus,
                      transactionID: merchantTransactionID,
                      transactionType: transactionType)),
            );
          }
          postTransaction(
            double.parse(widget.course.newAmount) > balance && payviawallet
                ? 'Wallet & $transactionType'
                : transactionType,
            adjustedAmount,
            widget.course.name,
            '${responseData["data"]["merchantTransactionId"]} , Bank Transaction Id: ${responseData["data"]["transactionId"]} ',
            widget.course.id,
          );
        } else {
          setState(() {
            paymentstatus = false;
          });
          // Payment Failed
        }
      } else {
        setState(() {
          paymentstatus = false;
        });
        throw Exception("Failed to fetch payment status");
      }
    } catch (e) {
      // Show Error Dialog
      setState(() {
        paymentstatus = false;
      });
    }
  }

  void paymentstatusnavigation() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PaymentPopUpPage(
              isWallet: false,
              adjustedAmount: double.parse(widget.course.newAmount),
              isSuccess: paymentstatus,
              transactionID: merchantTransactionID,
              transactionType: transactionType)),
    );
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Disable back navigation
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

  Future<void> postTransaction(String transactionName, int amount,
      String transactionType, String transactionID, int courseID) async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    // Define the API URL
    String apiUrl =
        "$baseUrl/api/buy-course/$userID/$courseID"; // Replace with your API URL

    // Create a Transaction instance
    final Transaction transaction = Transaction(
        type: "Purchased",
        transactionName: transactionName,
        amount: amount,
        transactionType: transactionType,
        transactionID: transactionID,
        description: "Course Purchase");

    try {
      // Make the POST request
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json", // Set headers if needed
          // Optional if authorization is required
        },
        body: jsonEncode(transaction.toJson()),
      );

      // Check the response status
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Transaction posted successfully: ${response.body}");
      } else {
        print(
            "Failed to post transaction: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("An error occurred: $e");
    }
  }
}
