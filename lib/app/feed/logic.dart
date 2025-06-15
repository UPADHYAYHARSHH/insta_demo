import 'package:get/get.dart';
import 'package:insta_demo/app/feed/state.dart';
import 'package:insta_demo/utils/database_helper.dart';
import 'package:insta_demo/utils/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:gal/gal.dart';

import '../login/view.dart';

class FeedLogic extends GetxController {
  final FeedState state = FeedState();
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() async {
    super.onInit();
    await DatabaseHelper.init();
    _loadDataFromHive();
    await _loadDummyImages();
    state.isLoadingInitialData.value = false;
  }

  void setUsername(String newUsername) {
    state.username.value = newUsername;
    DatabaseHelper.updateData('current_username', newUsername);
    _loadDataFromHive();
  }

  void _loadDataFromHive() {
    state.username.value =
        DatabaseHelper.readData<String>('current_username') ?? 'Anonymous';

    List<dynamic>? savedImageBase64s = DatabaseHelper.readData<List<dynamic>>(
      '${state.username.value}_uploaded_images',
    );
    if (savedImageBase64s != null) {
      state.uploadedImages.value =
          savedImageBase64s.map((e) => e as String).toList();
    } else {
      state.uploadedImages.clear();
    }

    List<dynamic>? savedTimestamps = DatabaseHelper.readData<List<dynamic>>(
      '${state.username.value}_uploaded_image_timestamps',
    );
    if (savedTimestamps != null) {
      state.uploadedImageTimestamps.value =
          savedTimestamps.map((e) => DateTime.parse(e as String)).toList();
    } else {
      state.uploadedImageTimestamps.clear();
    }

    List<dynamic>? savedCaptions = DatabaseHelper.readData<List<dynamic>>(
      '${state.username.value}_uploaded_image_captions',
    );
    if (savedCaptions != null) {
      state.uploadedImageCaptions.value =
          savedCaptions.map((e) => e as String).toList();
    } else {
      state.uploadedImageCaptions.clear();
    }

    List<dynamic>? savedUploadedIsLikedList =
        DatabaseHelper.readData<List<dynamic>>(
          '${state.username.value}_uploaded_post_liked_status',
        );
    if (savedUploadedIsLikedList != null) {
      state.uploadedImageIsLikedList.value =
          savedUploadedIsLikedList.map((e) => e as bool).toList();
    } else {
      state.uploadedImageIsLikedList.clear();
    }

    List<dynamic>? savedUploadedLikeCounts =
        DatabaseHelper.readData<List<dynamic>>(
          '${state.username.value}_uploaded_post_like_counts',
        );
    if (savedUploadedLikeCounts != null) {
      state.uploadedImageLikeCounts.value =
          savedUploadedLikeCounts.map((e) => e as int).toList();
    } else {
      state.uploadedImageLikeCounts.clear();
    }

    List<dynamic>? savedUploadedComments =
        DatabaseHelper.readData<List<dynamic>>(
          '${state.username.value}_uploaded_post_comments',
        );
    if (savedUploadedComments != null) {
      state.uploadedImageComments.value = _convertCommentData(
        savedUploadedComments,
      );
    } else {
      state.uploadedImageComments.clear();
    }

    List<dynamic>? savedIsLikedList = DatabaseHelper.readData<List<dynamic>>(
      '${state.username.value}_dummy_post_liked_status',
    );
    if (savedIsLikedList != null && savedIsLikedList.length >= 8) {
      state.isLikedList.value = savedIsLikedList
          .map((e) => e as bool)
          .toList()
          .sublist(0, 8);
    } else {
      state.isLikedList.value = List<bool>.generate(
        8,
        (index) =>
            savedIsLikedList != null && index < savedIsLikedList.length
                ? savedIsLikedList[index] as bool
                : false,
      );
    }
    // print('Loaded dummy_post_liked_status: ${state.isLikedList.value}');

    List<dynamic>? savedLikeCounts = DatabaseHelper.readData<List<dynamic>>(
      '${state.username.value}_dummy_post_like_counts',
    );
    if (savedLikeCounts != null && savedLikeCounts.length >= 8) {
      state.likeCounts.value = savedLikeCounts
          .map((e) => e as int)
          .toList()
          .sublist(0, 8);
    } else {
      state.likeCounts.value = List<int>.generate(
        8,
        (index) =>
            savedLikeCounts != null && index < savedLikeCounts.length
                ? savedLikeCounts[index] as int
                : 125 + (index * 23),
      );
    }
    // print('Loaded dummy_post_like_counts: ${state.likeCounts.value}');

    List<dynamic>? savedDummyComments = DatabaseHelper.readData<List<dynamic>>(
      'dummy_post_comments',
    );
    if (savedDummyComments != null) {
      state.dummyPostComments.value = _convertCommentData(savedDummyComments);
    } else {
      state.dummyPostComments.value = List<List<Map<String, String>>>.generate(
        8,
        (index) => [],
      );
    }


    if (state.uploadedImages.length != state.uploadedImageIsLikedList.length ||
        state.uploadedImages.length != state.uploadedImageLikeCounts.length ||
        state.uploadedImages.length != state.uploadedImageComments.length ||
        state.uploadedImages.length != state.uploadedImageTimestamps.length ||
        state.uploadedImages.length != state.uploadedImageCaptions.length) {
      state.uploadedImageIsLikedList.value = List.generate(
        state.uploadedImages.length,
        (index) => false,
      );
      state.uploadedImageLikeCounts.value = List.generate(
        state.uploadedImages.length,
        (index) => 0,
      );
      state.uploadedImageComments.value = List.generate(
        state.uploadedImages.length,
        (index) => [],
      );
      state.uploadedImageTimestamps.value = List.generate(
        state.uploadedImages.length,
        (index) => DateTime.now(),
      );
      state.uploadedImageCaptions.value = List.generate(
        state.uploadedImages.length,
        (index) => '',
      );

      DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_liked_status',
        state.uploadedImageIsLikedList.toList(),
      );
      DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_like_counts',
        state.uploadedImageLikeCounts.toList(),
      );
      DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_comments',
        state.uploadedImageComments
            .map((e) => e.map((x) => x).toList())
            .toList(),
      );
      DatabaseHelper.updateData(
        '${state.username.value}_uploaded_image_timestamps',
        state.uploadedImageTimestamps.map((e) => e.toIso8601String()).toList(),
      );
      DatabaseHelper.updateData(
        '${state.username.value}_uploaded_image_captions',
        state.uploadedImageCaptions.toList(),
      );
    }
  }

  Future<void> _loadDummyImages() async {
    for (String path in state.dummyImagePaths) {
      try {
        final ByteData data = await rootBundle.load(path);
        state.dummyPostBase64Images.add(
          base64Encode(data.buffer.asUint8List()),
        );
      } catch (e) {
        // print('Error loading dummy image from assets $path: $e');
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
      state.uploadedImages.insert(0, base64Image);
      state.uploadedImageIsLikedList.insert(0, false);
      state.uploadedImageLikeCounts.insert(0, 0);
      state.uploadedImageComments.insert(0, []);
      state.uploadedImageTimestamps.insert(0, DateTime.now());
      state.uploadedImageCaptions.insert(0, caption.trim());

      await DatabaseHelper.updateData(
        '${state.username.value}_uploaded_images',
        state.uploadedImages.toList(),
      );
      await DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_liked_status',
        state.uploadedImageIsLikedList.toList(),
      );
      await DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_like_counts',
        state.uploadedImageLikeCounts.toList(),
      );
      await DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_comments',
        state.uploadedImageComments
            .map((e) => e.map((x) => x).toList())
            .toList(),
      );
      await DatabaseHelper.updateData(
        '${state.username.value}_uploaded_image_timestamps',
        state.uploadedImageTimestamps.map((e) => e.toIso8601String()).toList(),
      );
      await DatabaseHelper.updateData(
        '${state.username.value}_uploaded_image_captions',
        state.uploadedImageCaptions.toList(),
      );
    }
  }

  void onLikeTapped(int index) {
    if (index >= 0 && index < state.isLikedList.length) {
      if (state.isLikedList[index]) {
        state.likeCounts[index]--;
      } else {
        state.likeCounts[index]++;
      }
      state.isLikedList[index] = !state.isLikedList[index];
      DatabaseHelper.updateData(
        '${state.username.value}_dummy_post_liked_status',
        state.isLikedList.toList(),
      );
      DatabaseHelper.updateData(
        '${state.username.value}_dummy_post_like_counts',
        state.likeCounts.toList(),
      );
    }
  }

  void onUploadedImageLikeTapped(int index) {
    if (index >= 0 && index < state.uploadedImageIsLikedList.length) {
      if (state.uploadedImageIsLikedList[index]) {
        state.uploadedImageLikeCounts[index]--;
      } else {
        state.uploadedImageLikeCounts[index]++;
      }
      state.uploadedImageIsLikedList[index] =
          !state.uploadedImageIsLikedList[index];
      DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_liked_status',
        state.uploadedImageIsLikedList.toList(),
      );
      DatabaseHelper.updateData(
        '${state.username.value}_uploaded_post_like_counts',
        state.uploadedImageLikeCounts.toList(),
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
          state.username.value.isNotEmpty
              ? state.username.value
              : (isUploadedImagePost
                  ? 'Anonymous'
                  : 'user_${(postIndex + 1).toString().padLeft(2, '0')}'),
      'comment': comment.trim(),
      'timestamp': timestamp,
    };

    if (isUploadedImagePost) {
      if (postIndex >= 0 && postIndex < state.uploadedImageComments.length) {
        state.uploadedImageComments[postIndex].add(commentData);
        state.uploadedImageComments.refresh();
        DatabaseHelper.updateData(
          '${state.username.value}_uploaded_post_comments',
          state.uploadedImageComments
              .map((e) => e.map((x) => x).toList())
              .toList(),

        );
        print('Added comment to uploaded post $postIndex: $commentData');
      }
    } else {
      if (postIndex >= 0 && postIndex < state.dummyPostComments.length) {
        state.dummyPostComments[postIndex].add(commentData);
        state.dummyPostComments.refresh();
        DatabaseHelper.updateData(
          'dummy_post_comments',
          state.dummyPostComments.map((e) => e.map((x) => x).toList()).toList(),
        );
        print('Added comment to dummy post $postIndex: $commentData');
      }
    }
  }

  Future<void> showLogoutDialog() async {
    await DatabaseHelper.deleteData(AppConstant.isLogin);
    state.username.value = 'Anonymous';
    state.uploadedImages.clear();
    state.uploadedImageTimestamps.clear();
    state.uploadedImageCaptions.clear();
    state.uploadedImageIsLikedList.clear();
    state.uploadedImageLikeCounts.clear();
    state.uploadedImageComments.clear();
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
      return true;
    }

    final hasAccess = await Gal.hasAccess(toAlbum: false);
    if (hasAccess) {
      return true;
    } else {
      try {
        await Gal.requestAccess(toAlbum: false);
        return true;
      } on GalException catch (e) {
        Get.snackbar(
          'Error',
          'Permission denied to access gallery: ${e.type.message}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to request gallery access: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    }
  }

  Future<void> downloadImage(int index, bool isUploadedImagePost) async {
    try {
      if (!kIsWeb) {
        final hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          return; // Permission denied, snackbar already shown in requestStoragePermission
        }
      }

      String? base64Image;
      if (isUploadedImagePost) {
        if (index >= 0 && index < state.uploadedImages.length) {
          base64Image = state.uploadedImages[index];
        }
      } else {
        if (index >= 0 && index < state.dummyPostBase64Images.length) {
          base64Image =
              state.dummyPostBase64Images[index %
                  state.dummyPostBase64Images.length];
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

      final bytes = base64Decode(base64Image);

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.Url.revokeObjectUrl(url);
        Get.snackbar(
          'Success',
          'Image download started.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        await Gal.putImageBytes(Uint8List.fromList(bytes));
        Get.snackbar(
          'Success',
          'Image saved to gallery.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } on GalException catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save image to gallery: ${e.type.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
