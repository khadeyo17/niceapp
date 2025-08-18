class BusSearchRequest {
  final String from;
  final String to;
  final DateTime travelDate;

  BusSearchRequest({
    required this.from,
    required this.to,
    required this.travelDate,
  });

  Map<String, dynamic> toJson() => {
    "from": from,
    "to": to,
    "travelDate": travelDate.toIso8601String(),
  };
}
