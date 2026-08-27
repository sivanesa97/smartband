import 'package:flutter_test/flutter_test.dart';
import 'package:smartband/Screens/Models/watch_data_payload.dart';

void main() {
  test('SmartSync BSW-50 17-byte payload parser test', () {
    // Example from Enthutech document:
    // (0x) 00-60-76-56-01-6c-61-00-00-00-d6-00-1e-00-0a-00-35
    final List<int> payloadBytes = [
      0x00, // Byte 0: SOS Status (00 = Disabled)
      0x60, // Byte 1: Heart Rate (0x60 = 96 BPM)
      0x76, // Byte 2: Systolic BP (0x76 = 118 mmHg)
      0x56, // Byte 3: Diastolic BP (0x56 = 86 mmHg)
      0x01, 0x6C, // Byte 4&5: Body Temp (0x016C = 364 -> 36.4 °C)
      0x61, // Byte 6: SpO2 (0x61 = 97 %)
      0x00, 0x00, 0x00, 0xD6, // Byte 7-10: Step Count (0x000000D6 = 214 Steps)
      0x00, 0x1E, // Byte 11&12: Sleep Wakefulness (0x001E = 30 Mins)
      0x00, 0x0A, // Byte 13&14: Sleep Light (0x000A = 10 Mins)
      0x00, 0x35, // Byte 15&16: Sleep Deep (0x0035 = 53 Mins)
    ];

    final payload = WatchDataPayload.fromBytes(payloadBytes);

    expect(payload.sosStatus, isFalse);
    expect(payload.heartRate, equals(96));
    expect(payload.systolicBp, equals(118));
    expect(payload.diastolicBp, equals(86));
    expect(payload.bodyTemp, equals(36.4));
    expect(payload.spo2, equals(97));
    expect(payload.stepCount, equals(214));
    expect(payload.sleepWakefulness, equals(30));
    expect(payload.sleepLight, equals(10));
    expect(payload.sleepDeep, equals(53));

    final map = payload.toMap();
    expect(map['sos_status'], equals('0'));
    expect(map['heart_rate'], equals('96'));
    expect(map['systolic_bp'], equals('118'));
    expect(map['diastolic_bp'], equals('86'));
    expect(map['body_temp'], equals('36.4'));
    expect(map['spo2'], equals('97'));
    expect(map['step_count'], equals('214'));
    expect(map['sleep_wakefulness'], equals('30'));
    expect(map['sleep_light'], equals('10'));
    expect(map['sleep_deep'], equals('53'));
  });
}
