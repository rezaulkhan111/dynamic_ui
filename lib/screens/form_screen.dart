import 'package:flutter/material.dart';
import '../services/json_loader.dart';

class FormScreen extends StatefulWidget {
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  Map<String, dynamic>? jsonData;
  Map<String, dynamic> formValues = {};
  final String lang = 'en';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final data = await JsonLoader.loadForm();
    Map<String, dynamic> initialValues = {};
    if (data["item_datas"] != null) {
      var itemDatas = data["item_datas"] as Map<String, dynamic>;
      for (var section in itemDatas.values) {
        var fields = section["fields"] as List<dynamic>;
        for (var field in fields) {
          initialValues[field["key"]] = field["data"];
        }
      }
    }

    setState(() {
      jsonData = data;
      formValues = initialValues;
    });
  }

  bool _isFieldVisible(Map<String, dynamic> field) {
    if (!field.containsKey('condition')) return true;
    var condition = field['condition'];
    var dependsOn = condition['depends_on'];
    var dependsOnValue = formValues[dependsOn];

    if (condition.containsKey('operator') && condition['operator'] == 'not_empty') {
      return dependsOnValue != null && dependsOnValue.toString().isNotEmpty;
    }
    return dependsOnValue.toString() == condition['value'].toString();
  }

  IconData _getIconForField(String key, String type) {
    if (key.contains('phone')) return Icons.phone;
    if (key.contains('name')) return Icons.person;
    if (key.contains('date') || type == 'date' || type == 'calendar') return Icons.calendar_today;
    if (key.contains('time') || type == 'time') return Icons.access_time;
    if (key.contains('city') || key.contains('stop')) return Icons.location_city;
    if (key.contains('price') || key.contains('fare') || key.contains('fee') || type == 'decimal') return Icons.attach_money;
    if (key.contains('luggage') || key.contains('baggage')) return Icons.luggage;
    if (key.contains('bus')) return Icons.directions_bus;
    if (key.contains('seat')) return Icons.event_seat;
    if (key.contains('policy') || key.contains('rule')) return Icons.gavel;
    if (key.contains('qr')) return Icons.qr_code_scanner;
    if (key.contains('verification')) return Icons.verified_user;
    if (type == 'boolean') return Icons.check_circle_outline;
    if (type == 'select') return Icons.list;
    return Icons.edit_note;
  }

  @override
  Widget build(BuildContext context) {
    if (jsonData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    var itemDatas = jsonData!["item_datas"] as Map<String, dynamic>;
    String appBarTitle = jsonData!["item_name"]?[lang] ?? "Dynamic Form";
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadData(),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: itemDatas.length,
        itemBuilder: (context, index) {
          String sectionKey = itemDatas.keys.elementAt(index);
          return _buildSectionCard(itemDatas[sectionKey]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          print("SUBMITTING FORM: $formValues");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: const Text("Form data saved successfully!"),
              backgroundColor: colorScheme.primary,
            ),
          );
        },
        label: const Text("Save Changes"),
        icon: const Icon(Icons.check_circle),
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    var title = section["title_lang"]?[lang] ?? "Section";
    var fields = section["fields"] as List<dynamic>;
    var visibleFields = fields.where((f) => _isFieldVisible(f)).toList();
    if (visibleFields.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.label_important_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: visibleFields.map((field) => _buildField(field)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    String key = field["key"];
    String label = field["label_lang"]?[lang] ?? key;
    String type = field["type"];
    dynamic value = formValues[key];
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _getIconForField(key, type);

    Widget fieldWidget;

    switch (type) {
      case 'string':
      case 'decimal':
      case 'text':
      case 'dd:hh:mm:ss':
      case 'hh:mm:ss':
        fieldWidget = TextFormField(
          key: Key(key),
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            hintText: field['required'] == true ? "Required" : null,
            filled: true,
            fillColor: colorScheme.surface,
          ),
          maxLines: type == 'text' ? 3 : 1,
          keyboardType: type == 'decimal'
              ? const TextInputType.numberWithOptions(decimal: true)
              : (key.contains('phone') ? TextInputType.phone : TextInputType.text),
          onChanged: (val) => setState(() => formValues[key] = val),
        );
        break;

      case 'boolean':
        bool boolValue = value == true || value == "1" || value == 1 || value.toString().toLowerCase() == "yes";
        fieldWidget = SwitchListTile(
          title: Text(label, style: const TextStyle(fontSize: 14)),
          secondary: Icon(icon, color: colorScheme.primary, size: 20),
          value: boolValue,
          activeColor: colorScheme.primary,
          onChanged: (val) => setState(() => formValues[key] = val),
          contentPadding: EdgeInsets.zero,
        );
        break;

      case 'select':
        List<Map<String, dynamic>> options = [];
        if (field.containsKey('options')) {
          options = (field['options'] as List).cast<Map<String, dynamic>>();
        } else if (field['data'] is String) {
          options = (field['data'] as String).split(',').map((o) => {'value': o.trim(), 'label_lang': {'en': o.trim()}}).toList();
        }

        String? currentValue = value?.toString();
        if (currentValue != null && !options.any((o) => o['value'].toString() == currentValue)) currentValue = null;

        fieldWidget = DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          items: options.map((opt) {
            String optValue = opt['value'].toString();
            return DropdownMenuItem(value: optValue, child: Text(opt['label_lang'][lang] ?? optValue));
          }).toList(),
          onChanged: (val) => setState(() => formValues[key] = val),
        );
        break;

      case 'date':
      case 'calendar':
      case 'time':
        fieldWidget = InkWell(
          onTap: () async {
            if (type == 'time') {
              TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (picked != null) {
                final localizations = MaterialLocalizations.of(context);
                setState(() => formValues[key] = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: true));
              }
            } else {
              DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
              if (picked != null) setState(() => formValues[key] = picked.toIso8601String().split('T')[0]);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, size: 20),
              filled: true,
              fillColor: colorScheme.surface,
            ),
            child: Text(value?.toString() ?? "Select ${type == 'time' ? 'time' : 'date'}"),
          ),
        );
        break;

      case 'object':
        fieldWidget = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer)),
                ],
              ),
              const SizedBox(height: 8),
              Text("Complex Configuration Data", style: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer.withOpacity(0.7))),
            ],
          ),
        );
        break;

      default:
        fieldWidget = ListTile(title: Text(label), subtitle: Text("Type: $type"));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: fieldWidget,
    );
  }
}
