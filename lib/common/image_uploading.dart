import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/main.dart';
import 'package:image/image.dart' as img;

class ImageUploadUtils {
  static Future<void> requestPermissions() async {
    if (kIsWeb) return; // No permissions needed on web

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

  static Future<File?> compressImage(File file, BuildContext context) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        showCustomToast(context, 'Error decoding image.');
        return null;
      }

      img.Image resized = img.copyResize(image, width: 1080, height: 720);

      final compressedBytes = img.encodeJpg(resized, quality: 75);

      final compressedFile =
          File('${file.parent.path}/compressed_${file.uri.pathSegments.last}')
            ..writeAsBytesSync(compressedBytes);

      return compressedFile;
    } catch (e) {
      showCustomToast(context, 'Error compressing image: $e');
      return null;
    }
  }

  static Future<String> uploadSingleImageFromGallery(
      BuildContext context) async {
    await requestPermissions();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      showCustomToast(context, 'No image selected.');
      return 'null';
    }

    if (kIsWeb) {
      // Handle web upload directly
      return await _uploadWebImage(image, context);
    } else {
      // Mobile handling with compression
      final compressedImage = await compressImage(File(image.path), context);
      if (compressedImage == null) {
        showCustomToast(context, 'Failed to compress image.');
        return 'null';
      }
      return await _uploadImage(compressedImage, context);
    }
  }

  static Future<String> uploadSingleImageFromCamera(
      BuildContext context) async {
    if (kIsWeb) {
      showCustomToast(context, 'Camera access not supported on web.');
      return 'null';
    }

    await requestPermissions();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) {
      showCustomToast(context, 'No image captured.');
      return 'null';
    }

    final compressedImage = await compressImage(File(image.path), context);
    if (compressedImage == null) {
      showCustomToast(context, 'Failed to compress image.');
      return 'null';
    }

    return await _uploadImage(compressedImage, context);
  }

  static Future<String> uploadMultipleImagesFromGallery(
      BuildContext context) async {
    await requestPermissions();
    final ImagePicker picker = ImagePicker();
    List<XFile> selectedImages = [];

    bool continueSelecting = true;

    while (continueSelecting) {
      final List<XFile> images = kIsWeb
          ? [await picker.pickImage(source: ImageSource.gallery)]
              .whereType<XFile>()
              .toList() // Web can only pick one at a time
          : await picker.pickMultiImage();

      if (images.isNotEmpty) {
        selectedImages.addAll(images);
      }

      if (selectedImages.isNotEmpty) {
        continueSelecting = await _showImageDialog(selectedImages);
      } else {
        break;
      }
    }

    if (selectedImages.isEmpty) {
      showCustomToast(context, 'No images selected.');
      return 'null';
    }

    List<String> downloadUrls = [];
    for (var image in selectedImages) {
      final String downloadUrl;

      if (kIsWeb) {
        downloadUrl = await _uploadWebImage(image, context);
      } else {
        final compressedImage = await compressImage(File(image.path), context);
        if (compressedImage == null) {
          showCustomToast(context, 'Failed to compress an image. Skipping.');
          continue;
        }
        downloadUrl = await _uploadImage(compressedImage, context);
      }

      if (downloadUrl != 'null') {
        downloadUrls.add(downloadUrl);
      }
    }

    return downloadUrls.isEmpty ? 'null' : downloadUrls.join(',');
  }

  static Future<String> uploadMultipleImagesFromCamera(
      BuildContext context) async {
    if (kIsWeb) {
      showCustomToast(context, 'Camera access not supported on web.');
      return 'null';
    }

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
        break;
      }
    }

    if (capturedImages.isEmpty) {
      showCustomToast(context, 'No images captured.');
      return 'null';
    }

    List<String> downloadUrls = [];
    for (var image in capturedImages) {
      final compressedImage = await compressImage(File(image.path), context);
      if (compressedImage == null) {
        showCustomToast(context, 'Failed to compress an image. Skipping.');
        continue;
      }

      final String downloadUrl = await _uploadImage(compressedImage, context);
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
                                child: kIsWeb
                                    ? Image.network(
                                        images[index].path,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
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
                if (!kIsWeb) // On web, we can't pick multiple at once
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

  static Future<String> _uploadImage(File image, BuildContext context) async {
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
        showCustomToast(context, 'Download URL not found in the response.');
        return 'null';
      }
    } else {
      showCustomToast(
          context, 'Failed to upload image: ${response.statusCode}');
      return 'null';
    }
  }

  static Future<String> _uploadWebImage(
      XFile image, BuildContext context) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload-profile');
      final request = http.MultipartRequest('POST', uri);

      // Convert XFile to bytes for web
      final bytes = await image.readAsBytes();
      final file = http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: image.name,
      );

      request.files.add(file);

      final response = await request.send();

      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

        if (jsonResponse.containsKey('download_url')) {
          return jsonResponse['download_url'] as String;
        } else {
          showCustomToast(context, 'Download URL not found in the response.');
          return 'null';
        }
      } else {
        showCustomToast(
            context, 'Failed to upload image: ${response.statusCode}');
        return 'null';
      }
    } catch (e) {
      showCustomToast(context, 'Error uploading image: $e');
      return 'null';
    }
  }
}
