class ChartPoint {
  final String x;
  final double y;

  const ChartPoint({
    required this.x,
    required this.y,
  });

  factory ChartPoint.fromMap(Map<String, dynamic> map) {
    return ChartPoint(
      x: map['x'].toString(),
      y: (map['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  ChartPoint copyWith({
    String? x,
    double? y,
  }) {
    return ChartPoint(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}