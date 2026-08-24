import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Messaging {
  static const String apiUrl =
      "https://msmsenterpriseapi.mobitel.lk/mSMSEnterpriseAPI/mSMSEnterpriseAPI.php";
  static const String apiUsername = "esmsusr_XHSgMMIG";
  static const String apiPassword = "pHbvqrSC";

  /// Mobitel Sender Alias / Mask assigned to your enterprise account.
  static String senderAlias = "LONG LIFE";

  static String? _sessionId;
  static DateTime? _sessionExpiry;

  /// Formats phone numbers to the Mobitel standard (e.g., 947XXXXXXXX).
  String _formatPhoneNumber(String phNo) {
    String cleaned = phNo.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '94${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') && cleaned.length == 9) {
      cleaned = '94$cleaned';
    }
    return cleaned;
  }

  /// Escapes special XML characters to prevent malformed SOAP payloads.
  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Obtains an active session ID from Mobitel ESMS API or reuses a valid cached session.
  Future<String?> _getSession({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _sessionId != null &&
        _sessionExpiry != null &&
        DateTime.now().isBefore(_sessionExpiry!)) {
      return _sessionId;
    }

    const sessionPayload = """<?xml version='1.0' encoding='utf-8'?>
<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
  <soap-env:Body>
    <ns0:createSession xmlns:ns0="https://ws.esms.mobitel.lk/">
      <user>
        <customer>0</customer>
        <id>0</id>
        <password>$apiPassword</password>
        <username>$apiUsername</username>
      </user>
    </ns0:createSession>
  </soap-env:Body>
</soap-env:Envelope>""";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '""',
        },
        body: sessionPayload,
      );

      if (response.statusCode == 200) {
        final sessionMatch =
            RegExp(r'<sessionId>(.*?)</sessionId>').firstMatch(response.body);
        final expiryMatch =
            RegExp(r'<expiryDate>(.*?)</expiryDate>').firstMatch(response.body);

        if (sessionMatch != null) {
          _sessionId = sessionMatch.group(1);
          if (expiryMatch != null) {
            try {
              _sessionExpiry = DateTime.parse(expiryMatch.group(1)!);
            } catch (_) {
              _sessionExpiry =
                  DateTime.now().add(const Duration(hours: 12));
            }
          }
          return _sessionId;
        }
      }
      debugPrint('Mobitel createSession failed: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('Error creating Mobitel session: $e');
    }
    return null;
  }

  /// Interprets Mobitel Enterprise SMS response status codes.
  String _describeResponseCode(String code) {
    switch (code) {
      case "200":
        return "Message sent OK";
      case "151":
        return "Invalid session";
      case "152":
        return "Session is still in use for previous request";
      case "155":
        return "Service halted";
      case "156":
        return "Other network messaging disabled";
      case "157":
        return "IDD messages disabled";
      case "159":
        return "Failed credit check / Insufficient balance";
      case "160":
        return "No message found";
      case "161":
        return "Message exceeding 160 characters";
      case "162":
        return "Invalid message type found";
      case "165":
        return "No recipients found";
      case "166":
        return "Recipient list exceeding allowed limit";
      case "169":
        return "Invalid alias / Sender Mask (check approved mask in Mobitel portal)";
      case "170":
        return "Blacklisted number in recipient list";
      case "171":
        return "Non-whitelisted number in recipient list";
      default:
        return "Response Code: $code";
    }
  }

  /// Sends an SMS via Mobitel Enterprise SMS service.
  void sendSMS(String phNo, String message) async {
    final formattedNumber = _formatPhoneNumber(phNo);
    final escapedMessage = _escapeXml(message);

    String? sessionId = await _getSession();
    if (sessionId == null) {
      debugPrint('Failed to send SMS: Unable to authenticate with Mobitel ESMS');
      return;
    }

    Future<String?> executeSend(String currentSessionId) async {
      final sendPayload = """<?xml version='1.0' encoding='utf-8'?>
<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
  <soap-env:Body>
    <ns0:sendMessages xmlns:ns0="https://ws.esms.mobitel.lk/">
      <session>
        <isActive>true</isActive>
        <sessionId>$currentSessionId</sessionId>
        <user>0</user>
      </session>
      <smsMessage>
        <message>$escapedMessage</message>
        <messageId>0</messageId>
        <recipients>$formattedNumber</recipients>
        <retries>0</retries>
        <sender>$senderAlias</sender>
        <sequenceNum>0</sequenceNum>
        <status>0</status>
        <messageType>0</messageType>
      </smsMessage>
    </ns0:sendMessages>
  </soap-env:Body>
</soap-env:Envelope>""";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '""',
        },
        body: sendPayload,
      );

      if (response.statusCode == 200) {
        final returnMatch =
            RegExp(r'<return>(.*?)</return>').firstMatch(response.body);
        return returnMatch?.group(1);
      }
      return null;
    }

    String? returnCode = await executeSend(sessionId);

    // If session was invalid/expired on server (Code 151), refresh session and retry once
    if (returnCode == "151") {
      debugPrint('Mobitel session expired, renewing session...');
      sessionId = await _getSession(forceRefresh: true);
      if (sessionId != null) {
        returnCode = await executeSend(sessionId);
      }
    }

    if (returnCode == "200") {
      debugPrint('Mobitel SMS sent successfully to $formattedNumber');
    } else {
      debugPrint(
          'Mobitel SMS status: ${_describeResponseCode(returnCode ?? "Unknown Error")} (to $formattedNumber)');
    }
  }
}


