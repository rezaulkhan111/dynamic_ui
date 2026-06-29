import 'dart:convert';

import 'package:flutter/services.dart';

class JsonLoader {
  static Future<Map<String, dynamic>> loadForm() async {
    String data = await rootBundle.loadString('assets/forms/ticket.json');

    return json.decode(data);
  }
}
