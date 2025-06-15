import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:insta_demo/app/feed/state.dart';
import 'package:insta_demo/utils/database_helper.dart';
import 'package:insta_demo/utils/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart' show AppTextStyles;
import '../login/view.dart';

class FeedLogic extends GetxController {
  final FeedState state = FeedState();
  var username = RxString('');
  var uploadedImages = <String>[].obs; // Store base64 strings
  var uploadedImageTimestamps = <DateTime>[].obs;
  var uploadedImageCaptions = <String>[].obs; // Store captions
  var isLikedList = List<bool>.generate(8, (index) => false).obs;
  var likeCounts = List<int>.generate(8, (index) => 125 + (index * 23)).obs;
  var uploadedImageIsLikedList = <bool>[].obs;
  var uploadedImageLikeCounts = <int>[].obs;
  var dummyPostComments =
      List<List<Map<String, String>>>.generate(8, (index) => []).obs;
  var uploadedImageComments = <List<Map<String, String>>>[].obs;
  var isLoadingInitialData = true.obs; // New loading indicator for initial data
  var dummyPostBase64Images =
      <String>[].obs; // Store base64 strings of dummy images

  final List<String> _dummyImagePaths = [
    'assets/images/joshua-reddekopp-SyYmXSDnJ54-unsplash.jpg',
    'assets/images/mohammad-rahmani-LrxSl4ZxoRs-unsplash.jpg',
    'assets/images/arnold-francisca-f77Bh3inUpE-unsplash.jpg',
    'assets/images/rear-view-programmer-working-all-night-long.jpg',
    'assets/images/computer-program-coding-screen.jpg',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() async {
    super.onInit();
    await DatabaseHelper.init(); // Ensure Hive is initialized
    _loadDataFromHive();
    await _loadDummyImages(); // Load dummy images from assets
    isLoadingInitialData.value = false; // Set to false after initial data load
  }

  void setUsername(String newUsername) {
    username.value = newUsername;
    DatabaseHelper.updateData('current_username', newUsername);
    _loadDataFromHive(); // Reload user-specific data
  }

  void _loadDataFromHive() {
    username.value =
        DatabaseHelper.readData<String>('current_username') ?? 'Anonymous';

    // Load user-specific data
    List<dynamic>? savedImageBase64s = DatabaseHelper.readData<List<dynamic>>(
      '${username.value}_uploaded_images',
    );
    if (savedImageBase64s != null) {
      uploadedImages.value = savedImageBase64s.map((e) => e as String).toList();
    } else {
      uploadedImages.clear();
    }

    List<dynamic>? savedTimestamps = DatabaseHelper.readData<List<dynamic>>(
      '${username.value}_uploaded_image_timestamps',
    );
    if (savedTimestamps != null) {
      uploadedImageTimestamps.value =
          savedTimestamps.map((e) => DateTime.parse(e as String)).toList();
    } else {
      uploadedImageTimestamps.clear();
    }

    List<dynamic>? savedCaptions = DatabaseHelper.readData<List<dynamic>>(
      '${username.value}_uploaded_image_captions',
    );
    if (savedCaptions != null) {
      uploadedImageCaptions.value =
          savedCaptions.map((e) => e as String).toList();
    } else {
      uploadedImageCaptions.clear();
    }

    List<dynamic>? savedUploadedIsLikedList =
        DatabaseHelper.readData<List<dynamic>>(
          '${username.value}_uploaded_post_liked_status',
        );
    if (savedUploadedIsLikedList != null) {
      uploadedImageIsLikedList.value =
          savedUploadedIsLikedList.map((e) => e as bool).toList();
    } else {
      uploadedImageIsLikedList.clear();
    }

    List<dynamic>? savedUploadedLikeCounts =
        DatabaseHelper.readData<List<dynamic>>(
          '${username.value}_uploaded_post_like_counts',
        );
    if (savedUploadedLikeCounts != null) {
      uploadedImageLikeCounts.value =
          savedUploadedLikeCounts.map((e) => e as int).toList();
    } else {
      uploadedImageLikeCounts.clear();
    }

    List<dynamic>? savedUploadedComments =
        DatabaseHelper.readData<List<dynamic>>(
          '${username.value}_uploaded_post_comments',
        );
    if (savedUploadedComments != null) {
      uploadedImageComments.value = _convertCommentData(savedUploadedComments);
    } else {
      uploadedImageComments.clear();
    }

    // Load global dummy post data
    List<dynamic>? savedIsLikedList = DatabaseHelper.readData<List<dynamic>>(
      'dummy_post_liked_status',
    );
    if (savedIsLikedList != null && savedIsLikedList.length >= 8) {
      isLikedList.value = savedIsLikedList
          .map((e) => e as bool)
          .toList()
          .sublist(0, 8);
    } else {
      isLikedList.value = List<bool>.generate(
        8,
        (index) =>
            savedIsLikedList != null && index < savedIsLikedList.length
                ? savedIsLikedList[index] as bool
                : false,
      );
    }
    print('Loaded dummy_post_liked_status: ${isLikedList.value}');

    List<dynamic>? savedLikeCounts = DatabaseHelper.readData<List<dynamic>>(
      'dummy_post_like_counts',
    );
    if (savedLikeCounts != null && savedLikeCounts.length >= 8) {
      likeCounts.value = savedLikeCounts
          .map((e) => e as int)
          .toList()
          .sublist(0, 8);
    } else {
      likeCounts.value = List<int>.generate(
        8,
        (index) =>
            savedLikeCounts != null && index < savedLikeCounts.length
                ? savedLikeCounts[index] as int
                : 125 + (index * 23),
      );
    }
    print('Loaded dummy_post_like_counts: ${likeCounts.value}');

    List<dynamic>? savedDummyComments = DatabaseHelper.readData<List<dynamic>>(
      'dummy_post_comments',
    );
    if (savedDummyComments != null) {
      dummyPostComments.value = _convertCommentData(savedDummyComments);
    } else {
      dummyPostComments.value = List<List<Map<String, String>>>.generate(
        8,
        (index) => [],
      );
    }
    print('Loaded dummy_post_comments: ${dummyPostComments.value}');

    // Ensure consistency in user-specific lists
    if (uploadedImages.length != uploadedImageIsLikedList.length ||
        uploadedImages.length != uploadedImageLikeCounts.length ||
        uploadedImages.length != uploadedImageComments.length ||
        uploadedImages.length != uploadedImageTimestamps.length ||
        uploadedImages.length != uploadedImageCaptions.length) {
      uploadedImageIsLikedList.value = List.generate(
        uploadedImages.length,
        (index) => false,
      );
      uploadedImageLikeCounts.value = List.generate(
        uploadedImages.length,
        (index) => 0,
      );
      uploadedImageComments.value = List.generate(
        uploadedImages.length,
        (index) => [],
      );
      uploadedImageTimestamps.value = List.generate(
        uploadedImages.length,
        (index) => DateTime.now(),
      );
      uploadedImageCaptions.value = List.generate(
        uploadedImages.length,
        (index) => '',
      );
      // Save corrected lists to Hive
      DatabaseHelper.updateData(
        '${username.value}_uploaded_post_liked_status',
        uploadedImageIsLikedList.toList(),
      );
      DatabaseHelper.updateData(
        '${username.value}_uploaded_post_like_counts',
        uploadedImageLikeCounts.toList(),
      );
      DatabaseHelper.updateData(
        '${username.value}_uploaded_post_comments',
        uploadedImageComments.map((e) => e.map((x) => x).toList()).toList(),
      );
      DatabaseHelper.updateData(
        '${username.value}_uploaded_image_timestamps',
        uploadedImageTimestamps.map((e) => e.toIso8601String()).toList(),
      );
      DatabaseHelper.updateData(
        '${username.value}_uploaded_image_captions',
        uploadedImageCaptions.toList(),
      );
    }
  }

  Future<void> _loadDummyImages() async {
    for (String path in _dummyImagePaths) {
      try {
        final ByteData data = await rootBundle.load(path);
        dummyPostBase64Images.add(base64Encode(data.buffer.asUint8List()));
      } catch (e) {
        print('Error loading dummy image from assets $path: $e');
      }
    }
  }

  Future<void> pickImage(ImageSource source, String caption) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      await processImage(image, caption);
    }
  }

  Future<void> processImage(XFile image, String caption) async {
    final base64Image = await DatabaseHelper.imageToBase64(image);
    if (base64Image != null) {
      uploadedImages.insert(0, base64Image);
      uploadedImageIsLikedList.insert(0, false);
      uploadedImageLikeCounts.insert(0, 0);
      uploadedImageComments.insert(0, []);
      uploadedImageTimestamps.insert(0, DateTime.now());
      uploadedImageCaptions.insert(0, caption.trim());

      await DatabaseHelper.updateData(
        '${username.value}_uploaded_images',
        uploadedImages.toList(),
      );
      await DatabaseHelper.updateData(
        '${username.value}_uploaded_post_liked_status',
        uploadedImageIsLikedList.toList(),
      );
      await DatabaseHelper.updateData(
        '${username.value}_uploaded_post_like_counts',
        uploadedImageLikeCounts.toList(),
      );
      await DatabaseHelper.updateData(
        '${username.value}_uploaded_post_comments',
        uploadedImageComments.map((e) => e.map((x) => x).toList()).toList(),
      );
      await DatabaseHelper.updateData(
        '${username.value}_uploaded_image_timestamps',
        uploadedImageTimestamps.map((e) => e.toIso8601String()).toList(),
      );
      await DatabaseHelper.updateData(
        '${username.value}_uploaded_image_captions',
        uploadedImageCaptions.toList(),
      );
    }
  }

  void onLikeTapped(int index) {
    if (index >= 0 && index < isLikedList.length) {
      if (isLikedList[index]) {
        likeCounts[index]--;
      } else {
        likeCounts[index]++;
      }
      isLikedList[index] = !isLikedList[index];
      DatabaseHelper.updateData(
        'dummy_post_liked_status',
        isLikedList.toList(),
      );
      DatabaseHelper.updateData('dummy_post_like_counts', likeCounts.toList());
    }
  }

  void onUploadedImageLikeTapped(int index) {
    if (index >= 0 && index < uploadedImageIsLikedList.length) {
      if (uploadedImageIsLikedList[index]) {
        uploadedImageLikeCounts[index]--;
      } else {
        uploadedImageLikeCounts[index]++;
      }
      uploadedImageIsLikedList[index] = !uploadedImageIsLikedList[index];
      DatabaseHelper.updateData(
        '${username.value}_uploaded_post_liked_status',
        uploadedImageIsLikedList.toList(),
      );
      DatabaseHelper.updateData(
        '${username.value}_uploaded_post_like_counts',
        uploadedImageLikeCounts.toList(),
      );
    }
  }

  void addComment(int postIndex, bool isUploadedImagePost, String comment) {
    if (comment.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Comment cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final commentData = {
      'username':
          username.value.isNotEmpty
              ? username.value
              : (isUploadedImagePost
                  ? 'Anonymous'
                  : 'user_${(postIndex + 1).toString().padLeft(2, '0')}'),
      'comment': comment.trim(),
      'timestamp': timestamp,
    };

    if (isUploadedImagePost) {
      if (postIndex >= 0 && postIndex < uploadedImageComments.length) {
        uploadedImageComments[postIndex].add(commentData);
        uploadedImageComments.refresh();
        DatabaseHelper.updateData(
          '${username.value}_uploaded_post_comments',
          uploadedImageComments.map((e) => e.map((x) => x).toList()).toList(),
        );
        print('Added comment to uploaded post $postIndex: $commentData');
      }
    } else {
      if (postIndex >= 0 && postIndex < dummyPostComments.length) {
        dummyPostComments[postIndex].add(commentData);
        dummyPostComments.refresh();
        DatabaseHelper.updateData(
          'dummy_post_comments',
          dummyPostComments.map((e) => e.map((x) => x).toList()).toList(),
        );
        print('Added comment to dummy post $postIndex: $commentData');
      }
    }
  }

  Future<void> showLogoutDialog() async {
    await DatabaseHelper.deleteData(AppConstant.isLogin);
    username.value = 'Anonymous';
    uploadedImages.clear();
    uploadedImageTimestamps.clear();
    uploadedImageCaptions.clear();
    uploadedImageIsLikedList.clear();
    uploadedImageLikeCounts.clear();
    uploadedImageComments.clear();
    Get.offAll(() => LoginPage());
  }

  String formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      return true; // No permissions needed for web
    }

    PermissionStatus status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      return true; // Other platforms (e.g., desktop) may not need permissions
    }

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await Get.defaultDialog(
        title: 'Permission Required',
        middleText:
            'Storage permission is needed to save images. Please enable it in settings.',
        confirmTextColor: Colors.white,
        radius: 12,
        onConfirm: () async {
          await openAppSettings();
          Get.back();
        },
        onCancel: () => Get.back(),
        buttonColor: AppColors.primary,
        cancelTextColor: AppColors.primary,
        titleStyle: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
        middleTextStyle: AppTextStyles.bodyMedium,
      );
      return false;
    } else {
      bool retry = false;
      await Get.defaultDialog(
        title: 'Permission Denied',
        middleText:
            'Storage permission is needed to save images. Would you like to try again?',
        confirmTextColor: Colors.white,
        radius: 12,
        onConfirm: () {
          retry = true;
          Get.back();
        },
        onCancel: () => Get.back(),
        buttonColor: AppColors.primary,
        cancelTextColor: AppColors.primary,
        titleStyle: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
        middleTextStyle: AppTextStyles.bodyMedium,
      );

      if (retry) {
        return await requestStoragePermission();
      }
      return false;
    }
  }

  Future<void> downloadImage(int index, bool isUploadedImagePost) async {
    try {
      if (!kIsWeb) {
        final hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          Get.snackbar(
            'Error',
            'Cannot download image without storage permission.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      String? base64Image;
      if (isUploadedImagePost) {
        if (index >= 0 && index < uploadedImages.length) {
          base64Image = uploadedImages[index];
        }
      } else {
        if (index >= 0 && index < dummyPostBase64Images.length) {
          base64Image =
              dummyPostBase64Images[index % dummyPostBase64Images.length];
        }
      }

      if (base64Image == null) {
        Get.snackbar(
          'Error',
          'Image data not available.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (kIsWeb) {
        final bytes = base64Decode(base64Image);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute(
                'download',
                'image_${DateTime.now().millisecondsSinceEpoch}.png',
              )
              ..click();
        html.Url.revokeObjectUrl(url);
        Get.snackbar(
          'Success',
          'Image download started.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          Get.snackbar(
            'Error',
            'Downloads directory not available.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${directory.path}/$fileName';
        final bytes = base64Decode(base64Image);
        await File(filePath).writeAsBytes(bytes);
        Get.snackbar(
          'Success',
          'Image saved to $filePath',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<List<Map<String, String>>> _convertCommentData(List<dynamic> data) {
    return data.asMap().entries.map((entry) {
      final postIndex = entry.key;
      final postComments = entry.value;
      if (postComments is List) {
        return postComments.asMap().entries.map((commentEntry) {
          final commentIndex = commentEntry.key;
          final comment = commentEntry.value;
          if (comment is String) {
            print(
              'Converting string comment at post $postIndex, comment $commentIndex: $comment',
            );
            return {
              'username': 'Anonymous',
              'comment': comment,
              'timestamp': DateTime.now().toIso8601String(),
            };
          } else if (comment is Map) {
            final converted = Map<String, String>.from(
              comment.cast<String, String>(),
            );
            converted['username'] ??= 'Anonymous';
            converted['timestamp'] ??= DateTime.now().toIso8601String();
            print(
              'Converted map comment at post $postIndex, comment $commentIndex: $converted',
            );
            return converted;
          }
          print(
            'Invalid comment data at post $postIndex, comment $commentIndex: $comment',
          );
          return {
            'username': 'Error',
            'comment': 'Invalid comment data',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }).toList();
      }
      print('Empty comment list at post $postIndex');
      return <Map<String, String>>[];
    }).toList();
  }
}
