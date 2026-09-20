enum DailyDiscoveryStatus {
  offered,
  claimed,
  empty,
}

DailyDiscoveryStatus dailyDiscoveryStatusFromJson(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  return DailyDiscoveryStatus.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => throw FormatException(
      'Unsupported Daily Discovery status: $value',
    ),
  );
}

class DailyDiscoveryState {
  const DailyDiscoveryState({
    required this.dateKey,
    required this.status,
    required this.offeredAt,
    this.cardId = '',
    this.conceptId = '',
    this.unlockEventId = '',
    this.claimedAt,
  });

  final String dateKey;
  final DailyDiscoveryStatus status;
  final DateTime offeredAt;
  final String cardId;
  final String conceptId;
  final String unlockEventId;
  final DateTime? claimedAt;

  bool get hasOffer => status != DailyDiscoveryStatus.empty;
  bool get isClaimed => status == DailyDiscoveryStatus.claimed;

  DailyDiscoveryState markClaimed(DateTime at) {
    if (!hasOffer) {
      throw StateError('Empty Daily Discovery cannot be claimed.');
    }
    return DailyDiscoveryState(
      dateKey: dateKey,
      status: DailyDiscoveryStatus.claimed,
      offeredAt: offeredAt,
      cardId: cardId,
      conceptId: conceptId,
      unlockEventId: unlockEventId,
      claimedAt: claimedAt ?? at,
    );
  }

  factory DailyDiscoveryState.fromJson(Map<String, dynamic> json) {
    final offeredAt = DateTime.tryParse(json['offeredAt']?.toString() ?? '');
    if (offeredAt == null) {
      throw const FormatException('Daily Discovery offeredAt is invalid.');
    }

    final claimedRaw = json['claimedAt']?.toString() ?? '';
    final claimedAt =
        claimedRaw.isEmpty ? null : DateTime.tryParse(claimedRaw);
    if (claimedRaw.isNotEmpty && claimedAt == null) {
      throw const FormatException('Daily Discovery claimedAt is invalid.');
    }

    final state = DailyDiscoveryState(
      dateKey: json['dateKey']?.toString() ?? '',
      status: dailyDiscoveryStatusFromJson(json['status']),
      offeredAt: offeredAt,
      cardId: json['cardId']?.toString() ?? '',
      conceptId: json['conceptId']?.toString() ?? '',
      unlockEventId: json['unlockEventId']?.toString() ?? '',
      claimedAt: claimedAt,
    );
    state.validate();
    return state;
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'status': status.name,
      'offeredAt': offeredAt.toIso8601String(),
      if (cardId.isNotEmpty) 'cardId': cardId,
      if (conceptId.isNotEmpty) 'conceptId': conceptId,
      if (unlockEventId.isNotEmpty) 'unlockEventId': unlockEventId,
      if (claimedAt != null) 'claimedAt': claimedAt!.toIso8601String(),
    };
  }

  void validate() {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) {
      throw FormatException('Invalid Daily Discovery date key: $dateKey');
    }

    if (status == DailyDiscoveryStatus.empty) {
      if (cardId.isNotEmpty ||
          conceptId.isNotEmpty ||
          unlockEventId.isNotEmpty ||
          claimedAt != null) {
        throw const FormatException(
          'Empty Daily Discovery cannot contain an offered card.',
        );
      }
      return;
    }

    if (cardId.isEmpty || conceptId.isEmpty || unlockEventId.isEmpty) {
      throw const FormatException(
        'Daily Discovery offer requires card, concept and event IDs.',
      );
    }

    if (status == DailyDiscoveryStatus.offered && claimedAt != null) {
      throw const FormatException(
        'Unclaimed Daily Discovery cannot have claimedAt.',
      );
    }

    if (status == DailyDiscoveryStatus.claimed && claimedAt == null) {
      throw const FormatException(
        'Claimed Daily Discovery requires claimedAt.',
      );
    }
  }
}
