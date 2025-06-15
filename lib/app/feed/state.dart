import 'package:get/get.dart';

class FeedState {
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

  final List<String> dummyImagePaths = [
    'assets/images/joshua-reddekopp-SyYmXSDnJ54-unsplash.jpg',
    'assets/images/mohammad-rahmani-LrxSl4ZxoRs-unsplash.jpg',
    'assets/images/arnold-francisca-f77Bh3inUpE-unsplash.jpg',
    'assets/images/rear-view-programmer-working-all-night-long.jpg',
    'assets/images/computer-program-coding-screen.jpg',
  ];

  FeedState() {
    ///Initialize variables
  }
  final int dummyPostCount = 5;
}
