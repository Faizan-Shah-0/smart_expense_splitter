class Trip {
  final String tripId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String adminUserId;
  final String joinCode;
  final List<String> participantUserIds;

  const Trip({
    required this.tripId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.adminUserId,
    required this.joinCode,
    required this.participantUserIds,
  });

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'title': title,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'adminUserId': adminUserId,
        'joinCode': joinCode,
        'participantUserIds': participantUserIds,
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        tripId: json['tripId'] as String,
        title: json['title'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        adminUserId: json['adminUserId'] as String,
        joinCode: json['joinCode'] as String,
        participantUserIds:
            (json['participantUserIds'] as List).map((e) => e as String).toList(),
      );
}



