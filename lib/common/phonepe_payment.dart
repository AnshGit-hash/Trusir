import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:trusir/common/api.dart';
// import 'package:trusir/common/custom_toast.dart';

class PaymentService {
  final String environmentValue =
      'SANDBOX'; // Use 'PRODUCTION' for live transactions
  final String appId = ""; // Replace with your App ID
  final String merchantId = "PGTESTPAYUAT86"; // Replace with your Merchant ID
  final String packageName =
      "com.phonepe.simulator"; // Change to "com.phonepe.app" for production
  final String apiEndPoint = "/pg/v1/pay";
  final String callback = "TrusirApp";
  final String saltKey = "96434309-7796-489d-8924-ab56988a6076";
  final String saltIndex = "1";

  /// Initialize the PhonePe SDK
  Future<void> initPhonePeSdk() async {
    try {
      bool isInitialized = await PhonePePaymentSdk.init(
          environmentValue, appId, merchantId, true);
      print("PhonePe SDK Initialized: $isInitialized");
    } catch (error) {
      print("Error initializing PhonePe SDK: $error");
      rethrow;
    }
  }

  String generateUniqueTransactionId(String userId) {
    // Hash the user ID to a shorter fixed length
    String userHash = sha256
        .convert(utf8.encode(userId))
        .toString()
        .substring(0, 8); // 8 characters
    int randomNum = Random().nextInt(10000); // Random 4-digit number
    print("txn_${userHash}_$randomNum");
    // Combine components to ensure <= 38 characters
    return "txn_${userHash}_$randomNum";
  }

  /// Generate checksum and return request body

  /// Start a transaction
  // void startTransaction(
  //     String body,
  //     String checksum,
  //     final checkStatus,
  //     final showLoadingDialog,
  //     final paymentstatusnavigation,
  //     BuildContext context) {
  //   showLoadingDialog();
  //   PhonePePaymentSdk.startTransaction(body, callback, checksum, packageName)
  //       .then((response) {
  //     if (response != null) {
  //       String status = response['status'].toString();
  //       if (status == 'SUCCESS') {
  //         print("Payment Successful");
  //         checkStatus();
  //       } else {
  //         print("Payment Failed: ${response['error']}");
  //         paymentstatusnavigation();
  //         showCustomToast(context, "Payment Failed");
  //       }
  //     } else {
  //       print("Transaction Incomplete");
  //       showCustomToast(context, 'Transaction Incomplete');
  //     }
  //   }).catchError((error) {
  //     print("Error during transaction: $error");
  //   });
  // }

  Future<bool> subWalletBalance(
      BuildContext context, String balance, String? userID) async {
    final String url = "$baseUrl/sub-balance/$userID/$balance";

    // Make PUT request
    final response = await http.get(Uri.parse(url));

    // Handle response
    if (response.statusCode == 200) {
      print("Wallet balance updated successfully: ${response.body}");
      return true;
    } else {
      print(
          "Failed to update balance: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  Future<bool> addWalletBalance(
      BuildContext context, String balance, String? userID) async {
    final String url = "$baseUrl/add-balance/$userID/$balance";

    // Make PUT request
    final response = await http.get(Uri.parse(url));

    // Handle response
    if (response.statusCode == 200) {
      print("Wallet balance updated successfully: ${response.body}");
      return true;
    } else {
      print(
          "Failed to update balance: ${response.statusCode} - ${response.body}");
      return false;
    }
  }
}
