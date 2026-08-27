import 'dart:typed_data';

class WatchDataPayload {
  final bool sosStatus; // Byte 0: 01=SOS Enabled, 00=SOS Disabled
  final int heartRate; // Byte 1: U8 BPM
  final int systolicBp; // Byte 2: U8 mmHg
  final int diastolicBp; // Byte 3: U8 mmHg
  final double bodyTemp; // Byte 4 & 5: U16 (°C = Actual Value / 10)
  final int spo2; // Byte 6: U8 %
  final int stepCount; // Byte 7..10: U32 Steps
  final int sleepWakefulness; // Byte 11 & 12: U16 Minutes
  final int sleepLight; // Byte 13 & 14: U16 Minutes
  final int sleepDeep; // Byte 15 & 16: U16 Minutes

  WatchDataPayload({
    required this.sosStatus,
    required this.heartRate,
    required this.systolicBp,
    required this.diastolicBp,
    required this.bodyTemp,
    required this.spo2,
    required this.stepCount,
    required this.sleepWakefulness,
    required this.sleepLight,
    required this.sleepDeep,
  });

  /// Parse 17-byte binary payload from SmartSync BSW-50 Watch
  factory WatchDataPayload.fromBytes(List<int> bytes) {
    if (bytes.length < 17) {
      throw ArgumentError('Payload must be at least 17 bytes long');
    }

    final ByteData bd = ByteData.sublistView(Uint8List.fromList(bytes));

    final bool sosStatus = (bd.getUint8(0) == 1);
    final int heartRate = bd.getUint8(1);
    final int systolicBp = bd.getUint8(2);
    final int diastolicBp = bd.getUint8(3);
    final int tempRaw = bd.getUint16(4, Endian.big);
    final double bodyTemp = tempRaw / 10.0;
    final int spo2 = bd.getUint8(6);
    final int stepCount = bd.getUint32(7, Endian.big);
    final int sleepWakefulness = bd.getUint16(11, Endian.big);
    final int sleepLight = bd.getUint16(13, Endian.big);
    final int sleepDeep = bd.getUint16(15, Endian.big);

    return WatchDataPayload(
      sosStatus: sosStatus,
      heartRate: heartRate,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      bodyTemp: bodyTemp,
      spo2: spo2,
      stepCount: stepCount,
      sleepWakefulness: sleepWakefulness,
      sleepLight: sleepLight,
      sleepDeep: sleepDeep,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sos_status': sosStatus ? '1' : '0',
      'heart_rate': heartRate.toString(),
      'systolic_bp': systolicBp.toString(),
      'diastolic_bp': diastolicBp.toString(),
      'body_temp': bodyTemp.toStringAsFixed(1),
      'spo2': spo2.toString(),
      'step_count': stepCount.toString(),
      'sleep_wakefulness': sleepWakefulness.toString(),
      'sleep_light': sleepLight.toString(),
      'sleep_deep': sleepDeep.toString(),
      'fall_axis': '--',
    };
  }

  @override
  String toString() {
    return 'WatchDataPayload(SOS: $sosStatus, HR: $heartRate BPM, BP: $systolicBp/$diastolicBp mmHg, Temp: $bodyTemp°C, SpO2: $spo2%, Steps: $stepCount, Sleep(W/L/D): $sleepWakefulness/$sleepLight/$sleepDeep mins)';
  }
}
