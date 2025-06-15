import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../utils/app_colors.dart';
import '../../utils/text_styles.dart';
import 'logic.dart';

class FeedPage extends StatelessWidget {
  FeedPage({super.key});

  final FeedLogic logic = Get.put(FeedLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Obx(
              () => Text(
                logic.username.value.isNotEmpty
                    ? logic.username.value
                    : 'InstaDemo',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                logic.showLogoutDialog();
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(
        () =>
            logic.isLoadingInitialData.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          await Future.delayed(const Duration(seconds: 1));
                        },
                        child: Obx(
                          () => ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                logic.uploadedImages.length +
                                logic.state.dummyPostCount,
                            itemBuilder: (context, index) {
                              if (index < logic.uploadedImages.length) {
                                return buildUploadedImagePost(
                                  context,
                                  logic.uploadedImages[index],
                                  index,
                                );
                              } else {
                                int dummyPostIndex =
                                    index - logic.uploadedImages.length;
                                return buildPostCard(context, dummyPostIndex);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: buildFloatingActionButton(context),
    );
  }

  Widget buildPostCard(BuildContext context, int index) {
    if (index < 0 ||
        index >= logic.isLikedList.length ||
        index >= logic.dummyPostComments.length) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://picsum.photos/40/40',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'user_${(index + 1).toString().padLeft(2, '0')}',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(
                          DateTime.now().subtract(const Duration(hours: 1)),
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            child: Image.network(
              'https://picsum.photos/400/300',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 250,
                  color: AppColors.grey100,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => buildActionButton(
                          icon:
                              logic.isLikedList[index]
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                          text: '${logic.likeCounts[index]} likes',
                          color:
                              logic.isLikedList[index]
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                          onTap: () => logic.onLikeTapped(index),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          text:
                              '${logic.dummyPostComments[index].length} comments',
                          color: AppColors.textSecondary,
                          onTap:
                              () => showCommentsDialog(context, index, false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildActionButton(
                        icon: Icons.download,
                        text: 'Download',
                        color: AppColors.textSecondary,
                        onTap: () => logic.downloadImage(index, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '#FlutterApp #DummyPost',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is a dummy post to showcase the app features.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUploadedImagePost(
    BuildContext context,
    String base64Image,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://picsum.photos/40/40',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          logic.username.value.isNotEmpty
                              ? logic.username.value
                              : 'Your Username',
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(logic.uploadedImageTimestamps[index]),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    height: 250,
                    color: AppColors.grey100,
                    child: const Center(
                      child: Icon(Icons.error, color: AppColors.error),
                    ),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => buildActionButton(
                          icon:
                              logic.uploadedImageIsLikedList[index]
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                          text: '${logic.uploadedImageLikeCounts[index]} likes',
                          color:
                              logic.uploadedImageIsLikedList[index]
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                          onTap: () => logic.onUploadedImageLikeTapped(index),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          text:
                              '${logic.uploadedImageComments[index].length} comments',
                          color: AppColors.textSecondary,
                          onTap: () => showCommentsDialog(context, index, true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildActionButton(
                        icon: Icons.download,
                        text: 'Download',
                        color: AppColors.textSecondary,
                        onTap: () => logic.downloadImage(index, true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '#YourPost #Flutter',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    logic.uploadedImageCaptions[index].isNotEmpty
                        ? logic.uploadedImageCaptions[index]
                        : 'No caption provided.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showImagePickerDialog(context);
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: AppColors.white),
    );
  }

  void showImagePickerDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Image Source',
          style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: Text('Gallery', style: AppTextStyles.bodyMedium),
              onTap: () async {
                Get.back();
                await pickImageAndShowCaptionDialog(
                  context,
                  ImageSource.gallery,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Camera', style: AppTextStyles.bodyMedium),
              onTap: () async {
                Get.back();
                await pickImageAndShowCaptionDialog(
                  context,
                  ImageSource.camera,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickImageAndShowCaptionDialog(
    BuildContext context,
    ImageSource source,
  ) async {
    final XFile? image = await ImagePicker().pickImage(source: source);
    if (image != null) {
      showCaptionDialog(context, image, source);
    }
  }

  void showCaptionDialog(
    BuildContext context,
    XFile image,
    ImageSource source,
  ) {
    TextEditingController captionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Caption',
          style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: captionController,
          decoration: InputDecoration(
            hintText: 'Enter a caption (optional)',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.grey100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: AppTextStyles.bodySmall,
          maxLines: 3,
          maxLength: 200, // Limit caption length
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              // Process the already-selected image with the caption
              await logic.processImage(image, captionController.text);
            },
            child: Text(
              'Post',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  void showCommentsDialog(
    BuildContext context,
    int postIndex,
    bool isUploadedImagePost,
  ) {
    TextEditingController commentController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          List<Map<String, String>> comments =
              isUploadedImagePost
                  ? logic.uploadedImageComments[postIndex]
                  : logic.dummyPostComments[postIndex];
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Comments',
                      style: AppTextStyles.h6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child:
                          comments.isEmpty
                              ? Center(
                                child: Text(
                                  'No comments yet.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final commentData = comments[index];
                                  final commentUsername =
                                      commentData['username'] ?? 'Anonymous';
                                  final commentText =
                                      commentData['comment'] ?? '';
                                  final commentTimestamp =
                                      commentData['timestamp'] != null
                                          ? DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(
                                            DateTime.parse(
                                              commentData['timestamp']!,
                                            ),
                                          )
                                          : 'Just now';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.grey100,
                                          child: Text(
                                            commentUsername.isNotEmpty
                                                ? commentUsername[0]
                                                    .toUpperCase()
                                                : 'A',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      commentUsername,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                AppColors
                                                                    .textPrimary,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    commentTimestamp,
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color:
                                                              AppColors
                                                                  .textSecondary,
                                                        ),
                                                    maxLines: 1,
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                commentText,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.grey100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: AppTextStyles.bodyMedium,
                            maxLines: null,
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (commentController.text.isNotEmpty) {
                              logic.addComment(
                                postIndex,
                                isUploadedImagePost,
                                commentController.text,
                              );
                              commentController.clear();
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Post',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void showLogoutDialog() {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Are you sure you want to logout?',
      confirmTextColor: AppColors.white,
      radius: 12,
      onConfirm: () async {
        Get.back();
        await logic.showLogoutDialog();
      },
      onCancel: () => Get.back(),
      buttonColor: AppColors.primary,
      cancelTextColor: AppColors.primary,
      titleStyle: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
      middleTextStyle: AppTextStyles.bodyMedium,
    );
  }
}
