import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';

class DeleteUtility {
  static Future<bool> deleteItem(
      String model, int id, BuildContext context) async {
    // If canceled, do nothing

    final String url = "$baseUrl/delete/$model/$id";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        showCustomToast(context, "$model Deleted Successfully");
        return true;
      } else {
        showCustomToast(context, "Error deleting $model with ID $id");
        return false;
      }
    } catch (e) {
      showCustomToast(context, "Error deleting $model with ID $id: $e");
      return false;
    }
  }
}
