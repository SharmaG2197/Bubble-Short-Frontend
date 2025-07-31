import 'package:flutter_dotenv/flutter_dotenv.dart';

final String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? "https://bubble-shot-api.onrender.com";
