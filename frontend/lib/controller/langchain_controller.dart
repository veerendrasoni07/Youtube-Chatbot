import 'dart:convert';

import 'package:frontend/global_variable.dart';
import 'package:http/http.dart' as http;

class LangchainController {
  Future<String> generateTranscript({required String ytUrl}) async {
    try {
      http.Response response = await http.post(
        Uri.parse('$uri/api/generate-transcript'),
        body: jsonEncode({"link": ytUrl}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        print(
          "GOT THE RESPONEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE",
        );
        final data = jsonDecode(response.body);
        return data['session_id'];
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception("Something went wrong:$e");
    }
  }

  Future<String> chatWithVideo({
    required String message,
    required String sessionId,
  }) async {
    try {
      http.Response response = await http.post(
        Uri.parse('$uri/api/chat'),
        body: jsonEncode({"message": message, "session_id": sessionId}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception("Something went wrong:$e");
    }
  }
}
