import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/dashboard/domain/fill.dart';

class HyperliquidClient {
  static const _baseUrl = 'https://api.hyperliquid.xyz/info';

  Future<List<Fill>> fetchUserFills(String address) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'type': 'userFills', 'user': address}),
    );

    if (response.statusCode != 200) {
      throw HyperliquidException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((raw) => Fill.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<List<Fill>> fetchUserFillsByTime(
    String address,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': 'userFillsByTime',
        'user': address,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode != 200) {
      throw HyperliquidException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((raw) => Fill.fromJson(raw as Map<String, dynamic>))
        .toList();
  }
}

class HyperliquidException implements Exception {
  final int statusCode;
  final String body;

  const HyperliquidException(this.statusCode, this.body);

  @override
  String toString() => 'HyperliquidException($statusCode): $body';
}
