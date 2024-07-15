import 'dart:convert';
import 'package:http/http.dart' as http;

class TwilioService {
  final String accountSid;
  final String authToken;
  final String fromNumber;

  TwilioService({
    required this.accountSid,
    required this.authToken,
    required this.fromNumber,
  });

  Future<void> makeCall(String toNumber, String twimlUrl) async {
    final String url = 'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Calls.json';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'From': fromNumber,
        'To': toNumber,
        'Twiml': twimlUrl,
      },
    );

    if (response.statusCode == 201) {
      print('Call initiated successfully.');
    } else {
      print('Failed to initiate call. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> sendSms(String toNumber, String message) async {
    final String url = 'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'From': fromNumber,
        'To': toNumber,
        'Body': message,
      },
    );

    if (response.statusCode == 201) {
      print('Message sent successfully.');
    } else {
      print('Failed to send message. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }
}
