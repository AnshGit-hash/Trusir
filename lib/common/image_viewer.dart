import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/custom_toast.dart';
import 'dart:convert';
import 'package:trusir/common/file_downloader.dart';

class ImageViewerScreen extends StatefulWidget {
  final String imagePath;
  final bool downloaded;
  final String title;

  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    required this.title,
    required this.downloaded,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late String _currentImagePath;
  late bool _isDownloaded;
  bool _isDeleting = false; // Flag to track delete progress

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _isDownloaded = widget.downloaded;
    FileDownloader.loadDownloadedFiles();
  }

  Future<void> _deleteImage() async {
    setState(() {
      _isDeleting = true; // Show loading indicator
    });

    try {
      final file = File(_currentImagePath);
      if (await file.exists()) {
        await file.delete();
        await _removeFromSharedPreferences(widget.title);

        setState(() {
          _isDownloaded = false;
          _currentImagePath = widget.imagePath; // Reset to original URL
          _isDeleting = false; // Stop loading indicator
        });

        showCustomToast(context, 'Image deleted successfully');
      }
    } catch (e) {
      setState(() {
        _isDeleting = false; // Stop loading indicator on error
      });

      showCustomToast(context, 'Failed to delete image: $e');
    }
  }

  Future<void> _removeFromSharedPreferences(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final savedFiles = prefs.getString('downloadedTests') ?? '{}';

    Map<String, String> downloadedFiles =
        Map<String, String>.from(jsonDecode(savedFiles));

    if (downloadedFiles.containsKey(filename)) {
      downloadedFiles.remove(filename);
      await prefs.setString('downloadedTests', jsonEncode(downloadedFiles));
    }
  }

  void _onDownloadComplete(String newPath) {
    setState(() {
      _currentImagePath = newPath;
      _isDownloaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18), // optional style
              ),
            ),
            if (_isDeleting)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (!_isDownloaded)
              IconButton(
                onPressed: () {
                  FileDownloader.downloadFile(
                    context,
                    widget.imagePath,
                    widget.title,
                    _onDownloadComplete,
                  );
                },
                icon: const Icon(Icons.download),
              )
            else
              IconButton(
                onPressed: _deleteImage,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
          ],
        ),
      ),
      body: _isDeleting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : PhotoView(
              imageProvider: _isDownloaded
                  ? FileImage(File(_currentImagePath)) as ImageProvider
                  : NetworkImage(_currentImagePath),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
    );
  }
}
