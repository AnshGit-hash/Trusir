import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/notificationhelper.dart';

class FileDownloader {
  static Map<String, String> downloadedFiles = {};

  static Future<String> getAppSpecificDownloadPath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  static Future<void> downloadFile(
    BuildContext context,
    String url,
    String filename,
  ) async {
    try {
      String fileExtension = _getFileExtensionFromUrl(url);
      String finalFilename = '$filename$fileExtension';

      final filePath = await getAppSpecificDownloadPath(finalFilename);
      await _requestNotificationPermission();
      final dio = Dio();
      await dio.download(url, filePath);

      downloadedFiles[finalFilename] = filePath;
      downloadedFiles[filename] = filePath;

      await _saveDownloadedFiles();
      showDownloadNotification(finalFilename, filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static String _getFileExtensionFromUrl(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return '.jpg';
      case 'png':
        return '.png';
      default:
        return ''; // Default case
    }
  }

  // static Future<void> openFile(String filename) async {
  //   final filePath = downloadedFiles[filename];
  //   if (filePath != null) {
  //     await OpenFile.open(filePath);
  //   }
  // }

  static Future<void> openFile(
      BuildContext context, String filename, String url) async {
    final filePath = downloadedFiles[filename];
    if (filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            imagePath: filePath,
            downloaded: true,
            title: filename,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            imagePath: url,
            downloaded: false,
            title: filename,
          ),
        ),
      );
    }
  }

  static Future<void> loadDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFiles = prefs.getString('downloadedTests') ?? '{}';
    downloadedFiles = Map<String, String>.from(jsonDecode(savedFiles));
  }

  static Future<void> _saveDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('downloadedTests', jsonEncode(downloadedFiles));
  }

  static Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final bool downloaded;
  final String title;

  const ImageViewerScreen(
      {super.key,
      required this.imagePath,
      required this.title,
      required this.downloaded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          Text(title),
          const Spacer(),
          !downloaded
              ? IconButton(
                  onPressed: () {
                    FileDownloader.downloadFile(context, imagePath, title);
                  },
                  icon: const Icon(Icons.download))
              : const SizedBox()
        ],
      )),
      body: !downloaded
          ? Center(
              child: Image.network(imagePath, fit: BoxFit.contain),
            )
          : Center(
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
    );
  }
}
