import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double> fetchGoldPriceUSD() async {
  final response = await http.get(
    Uri.parse('https://www.gold-api.com/api/XAU/USD/1'),
  );

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return (json['price'] as num).toDouble();
  } else {
    throw Exception("Failed to load gold price");
  }
}