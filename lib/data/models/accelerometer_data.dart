class AccelerometerData {
  final DateTime timestamp;
  final List<double> x;
  final List<double> y;
  final List<double> z;
  final int isSent;

  AccelerometerData({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    this.isSent = false ? 1 : 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'x': x.map((x) => x).join(", "),
      'y': y.map((y) => y).join(", "),
      'z': z.map((z) => z).join(", "),
      'is_sent': isSent,
    };
  }
}
