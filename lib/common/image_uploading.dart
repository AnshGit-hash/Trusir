import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:trusir/common/api.dart';
import 'package:trusir/main.dart';
import 'package:image/image.dart' as img;

class ImageUploadUtils {
  static Future<void> requestPermissions() async {
    if (await Permission.camera.isGranted) {
      return;
    }

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt < 30) {
        return;
      }

      if (await Permission.camera.isGranted) {
        return;
      }

      Map<Permission, PermissionStatus> statuses =
          await [Permission.camera].request();

      if (statuses.values.any((status) => !status.isGranted)) {
        openAppSettings();
      }
    }
  }

  static Future<File?> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        Fluttertoast.showToast(msg: 'Error decoding image.');
        return null;
      }

      img.Image resized = img.copyResize(image, width: 1080, height: 720);

      final compressedBytes = img.encodeJpg(resized, quality: 75);

      final compressedFile =
          File('${file.parent.path}/compressed_${file.uri.pathSegments.last}')
            ..writeAsBytesSync(compressedBytes);

      return compressedFile;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error compressing image: $e');
      return null;
    }
  }

  static Future<String> uploadSingleImageFromGallery() async {
    await requestPermissions();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      Fluttertoast.showToast(msg: 'No image selected.');
      return 'null';
    }

    final compressedImage = await compressImage(File(image.path));
    if (compressedImage == null) {
      Fluttertoast.showToast(msg: 'Failed to compress image.');
      return 'null';
    }

    return await _uploadImage(compressedImage);
  }

  static Future<String> uploadSingleImageFromCamera() async {
    await requestPermissions();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) {
      Fluttertoast.showToast(msg: 'No image captured.');
      return 'null';
    }

    final compressedImage = await compressImage(File(image.path));
    if (compressedImage == null) {
      Fluttertoast.showToast(msg: 'Failed to compress image.');
      return 'null';
    }

    return await _uploadImage(compressedImage);
  }

  static Future<String> uploadMultipleImagesFromGallery() async {
    await requestPermissions();
    final ImagePicker picker = ImagePicker();
    List<XFile> selectedImages = [];

    bool continueSelecting = true;

    while (continueSelecting) {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        selectedImages.addAll(images);
      }

      if (selectedImages.isNotEmpty) {
        continueSelecting = await _showImageDialog(selectedImages);
      } else {
        break; // Prevents the dialog from appearing if no images were selected
      }
    }

    if (selectedImages.isEmpty) {
      Fluttertoast.showToast(msg: 'No images selected.');
      return 'null';
    }

    List<String> downloadUrls = [];
    for (var image in selectedImages) {
      final compressedImage = await compressImage(File(image.path));
      if (compressedImage == null) {
        Fluttertoast.showToast(msg: 'Failed to compress an image. Skipping.');
        continue;
      }
      final String downloadUrl = await _uploadImage(compressedImage);
      if (downloadUrl != 'null') {
        downloadUrls.add(downloadUrl);
      }
    }

    return downloadUrls.isEmpty ? 'null' : downloadUrls.join(',');
  }

  // Function to upload multiple images from the camera
  static Future<String> uploadMultipleImagesFromCamera() async {
    await requestPermissions();
    final ImagePicker picker = ImagePicker();
    List<XFile> capturedImages = [];

    bool continueCapturing = true;

    while (continueCapturing) {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        capturedImages.add(image);
      }

      if (capturedImages.isNotEmpty) {
        continueCapturing = await _showImageDialog(capturedImages);
      } else {
        break; // Prevents the dialog from appearing if no images were captured
      }
    }

    if (capturedImages.isEmpty) {
      Fluttertoast.showToast(msg: 'No images captured.');
      return 'null';
    }

    List<String> downloadUrls = [];
    for (var image in capturedImages) {
      final compressedImage = await compressImage(File(image.path));
      if (compressedImage == null) {
        Fluttertoast.showToast(msg: 'Failed to compress an image. Skipping.');
        continue;
      }

      final String downloadUrl = await _uploadImage(compressedImage);
      if (downloadUrl != 'null') {
        downloadUrls.add(downloadUrl);
      }
    }

    return downloadUrls.isEmpty ? 'null' : downloadUrls.join(',');
  }

  static Future<bool> _showImageDialog(List<XFile> images) async {
    return await showDialog(
          context: navigatorKey.currentContext!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Selected Images'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  File(images[index].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () {
                                    images.removeAt(index);
                                    Navigator.pop(context);
                                    _showImageDialog(images);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false), // Done
                  child: const Text('Done'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true), // Add More
                  child: const Text('Add More'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<String> _uploadImage(File image) async {
    final uri = Uri.parse('$baseUrl/api/upload-profile');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('photo', image.path));

    final response = await request.send();

    if (response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

      if (jsonResponse.containsKey('download_url')) {
        return jsonResponse['download_url'] as String;
      } else {
        Fluttertoast.showToast(msg: 'Download URL not found in the response.');
        return 'null';
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Failed to upload image: ${response.statusCode}');
      return 'null';
    }
  }
}
