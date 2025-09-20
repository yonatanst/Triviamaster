import 'package:triviamaster/src/services/api_service.dart';

class QuestionService {
  static Future<Map<String, dynamic>> nextQuestion({
    required String uid,
    required int rating,
    required String category,
    required List<String> seenKeys,
    String locale = 'en',
  }) async {
    return ApiService.fetchQuestion(
      uid: uid,
      rating: rating,
      category: category,
      seen: seenKeys,
      locale: locale,
    );
  }
}
