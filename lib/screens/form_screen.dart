import 'package:flutter/material.dart';

import '../services/json_loader.dart';

class FormScreen extends StatefulWidget {
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  Map<String, dynamic>? jsonData;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final data = await JsonLoader.loadForm();

    print("JSON LOADED: $data"); // 🔥 test

    setState(() {
      jsonData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (jsonData == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Take first field only (beginner step)
    var fields = jsonData!["item_datas"]["identification_client"]["fields"];

    var firstField = fields[0];

    return Scaffold(
      appBar: AppBar(title: Text("Dynamic Form")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "First field: ${firstField["label_lang"]["en"]}",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
