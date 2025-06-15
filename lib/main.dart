import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'app/login/view.dart';
import 'app/feed/view.dart';
import 'package:insta_demo/utils/database_helper.dart';
import 'package:insta_demo/utils/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn =
        DatabaseHelper.readData(AppConstant.isLogin) == 'true';
    return GetMaterialApp(
      title: 'Instagram Demo',
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? FeedPage() : LoginPage(),
    );
  }
}
