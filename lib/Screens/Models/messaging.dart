import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class Messaging{

  void sendSMS(String phNo, String Message) async {
    String apiUsername = "ggpd_user";
    String apiPassword = "669f8ffb258c2";
    String apiUrl = "https://richcommunication.dialog.lk/api/sms/send";

    String digest = md5.convert(utf8.encode(apiPassword)).toString();
    String created = DateTime.now().toUtc().toIso8601String();

    // Prepare the headers
    Map<String, String> headers = {
      "USER": apiUsername,
      "DIGEST": digest,
      "CREATED": created,
      "Content-Type": "application/json"
    };

    // Prepare the payload
    phNo = phNo.replaceAll("+", "");
    Map<String, dynamic> payload = {
      "messages": [
        {
          "clientRef": "7945695",
          "number": phNo,
          "mask": "GG CARE",
          "text": Message,
          "campaignName": "phoneotp"
        }
      ]
    };

    // Make the POST request
    http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(payload),
    );

    // Print the response
    if (response.statusCode == 200) {
      print('Message sent successfully');
      print(response.body);
    } else {
      print('Failed to send message');
      print(response.statusCode);
      print(response.body);
    }
  }
}
