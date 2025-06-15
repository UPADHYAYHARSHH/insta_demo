import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:insta_demo/app/feed/view.dart';
import 'package:insta_demo/app/login/state.dart';
import 'package:insta_demo/utils/app_constants.dart';
import 'package:insta_demo/utils/database_helper.dart';

class LoginLogic extends GetxController {
  LoginState state = LoginState();

  Future<void> login() async {
    final username = state.usernameController.text;
    if (username.isNotEmpty) {
      await DatabaseHelper.init();
      await DatabaseHelper.updateData('current_username', username);
      await DatabaseHelper.updateData(AppConstant.isLogin, 'true');
      Get.offAll(() => FeedPage());
    } else {
      Get.snackbar(
        'Error',
        'Username cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    state.usernameController.dispose();
    super.onClose();
  }
}
