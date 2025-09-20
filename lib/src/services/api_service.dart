//'https://triviamaster-4kjl4hg4x-yonatans-projects-66006f77.vercel.app/api/genQuestion';
//$uri  = 'https://triviamaster-4kjl4hg4x-yonatans-projects-66006f77.vercel.app/api/genQuestion'
//$body = @{ uid='smoketest'; rating=1200; categories=@('geography'); seen=@(); locale='en' } | ConvertTo-Json -Compress
//Invoke-RestMethod -Method Post -Uri $uri -ContentType 'text/plain' -Body $body


import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: paste your deployed domain here
  static const String _endpoint =
      'https://triviamaster-4kjl4hg4x-yonatans-projects-66006f77.vercel.app/api/genQuestion';

  static Future<Map<String, dynamic>> fetchQuestion({
    required String uid,
    required int rating,
    required String category,
    required List<String> seen,
    String locale = 'en',
  }) async {
    final resp = await http.post(
      Uri.parse(_endpoint),
      // text/plain keeps it a "simple request" and avoids CORS preflight
      headers: const {'Content-Type': 'text/plain'},
      body: jsonEncode({
        'uid': uid,
        'rating': rating,
        'categories': [category],
        'seen': seen,
        'locale': locale,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }

    final json = jsonDecode(resp.body);
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    return json;
  }
}
