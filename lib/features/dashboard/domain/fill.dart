class Fill {
  final String coin;
  final double price;
  final double size;
  final String side;
  final String direction;
  final DateTime time;
  final double closedPnl;
  final double fee;
  final String feeToken;
  final String tid;
  final double startPosition;

  const Fill({
    required this.coin,
    required this.price,
    required this.size,
    required this.side,
    required this.direction,
    required this.time,
    required this.closedPnl,
    required this.fee,
    required this.feeToken,
    required this.tid,
    required this.startPosition,
  });

  factory Fill.fromJson(Map<String, dynamic> json) {
    return Fill(
      coin: json['coin'] as String,
      price: double.parse(json['px'] as String),
      size: double.parse(json['sz'] as String),
      side: json['side'] as String,
      direction: json['dir'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
      closedPnl: double.parse(json['closedPnl'] as String),
      fee: double.parse(json['fee'] as String),
      feeToken: json['feeToken'] as String,
      tid: json['tid'].toString(),
      startPosition: double.tryParse(json['startPosition']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coin': coin,
      'px': price.toString(),
      'sz': size.toString(),
      'side': side,
      'dir': direction,
      'time': time.millisecondsSinceEpoch,
      'closedPnl': closedPnl.toString(),
      'fee': fee.toString(),
      'feeToken': feeToken,
      'tid': tid,
      'startPosition': startPosition.toString(),
    };
  }

  // Position size after this fill, signed: positive = net long, negative =
  // net short. Derived from startPosition + the signed size this fill adds.
  double get positionAfter => startPosition + (side == 'B' ? size : -size);
}
