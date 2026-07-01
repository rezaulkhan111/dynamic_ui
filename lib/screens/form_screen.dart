import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/json_loader.dart';

class FormScreen extends StatefulWidget {
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? jsonData;
  Map<String, dynamic> formValues = {};
  String currentLang = 'en';

  final Map<String, String> langNames = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
    'es': 'Español',
    'pt': 'Português',
    'cn': '中文',
  };

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

    if (condition.containsKey('operator') &&
        condition['operator'] == 'not_empty') {
      return dependsOnValue != null && dependsOnValue.toString().isNotEmpty;
    }
    return dependsOnValue.toString() == condition['value'].toString();
  }

  IconData _getIconForField(String key, String type) {
    if (key.contains('phone')) return Icons.phone;
    if (key.contains('name')) return Icons.person;
    if (key.contains('date') || type == 'date' || type == 'calendar')
      return Icons.calendar_today;
    if (key.contains('time') || type == 'time') return Icons.access_time;
    if (key.contains('city') || key.contains('stop'))
      return Icons.location_city;
    if (key.contains('price') ||
        key.contains('fare') ||
        key.contains('fee') ||
        type == 'decimal')
      return Icons.attach_money;
    if (key.contains('luggage') || key.contains('baggage'))
      return Icons.luggage;
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
    String appBarTitle = jsonData!["item_name"]?[currentLang] ?? "Dynamic Form";
    final colorScheme = Theme.of(context).colorScheme;

    // Extract available languages from JSON
    List<String> availableLangs = [];
    if (jsonData!["item_name"] is Map) {
      availableLangs = (jsonData!["item_name"] as Map).keys.cast<String>().toList();
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
            onSelected: (String lang) {
              setState(() {
                currentLang = lang;
              });
            },
            itemBuilder: (BuildContext context) {
              return availableLangs.map((String langCode) {
                return PopupMenuItem<String>(
                  value: langCode,
                  child: Row(
                    children: [
                      Text(
                        langCode.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(langNames[langCode] ?? langCode),
                      if (currentLang == langCode) ...[
                        const Spacer(),
                        Icon(Icons.check, color: colorScheme.primary, size: 16),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadData(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: itemDatas.length,
          itemBuilder: (context, index) {
            String sectionKey = itemDatas.keys.elementAt(index);
            return _buildSectionCard(itemDatas[sectionKey]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            print("SUBMITTING FORM: $formValues");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: const Text("Form data saved successfully!"),
                backgroundColor: colorScheme.primary,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text("Please fix the errors in the form"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        label: const Text("Save Changes"),
        icon: const Icon(Icons.check_circle),
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    var title = section["title_lang"]?[currentLang] ?? "Section";
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.label_important_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
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
              children: visibleFields
                  .map((field) => _buildField(field))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    String key = field["key"];
    String label = field["label_lang"]?[currentLang] ?? key;
    String type = field["type"];
    dynamic value = formValues[key];
    bool isRequired = field["required"] == true;
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _getIconForField(key, type);

    Widget fieldWidget;

    String? validator(String? val) {
      if (isRequired && (val == null || val.isEmpty)) {
        return "This field is required";
      }
      if (key.contains('phone') && val != null && val.isNotEmpty) {
        if (!RegExp(r'^[0-9]+$').hasMatch(val)) {
          return "Please enter only numbers";
        }
      }
      return null;
    }

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
            hintText: isRequired ? "Required" : null,
          ),
          maxLines: type == 'text' ? 3 : 1,
          keyboardType: type == 'decimal'
              ? const TextInputType.numberWithOptions(decimal: true)
              : (key.contains('phone')
                    ? TextInputType.phone
                    : TextInputType.text),
          inputFormatters: key.contains('phone') || type == 'decimal'
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
          onChanged: (val) {
            formValues[key] = val;
            setState(() {});
          },
          validator: validator,
        );
        break;

      case 'boolean':
        bool boolValue =
            value == true ||
            value == "1" ||
            value == 1 ||
            value.toString().toLowerCase() == "yes";
        fieldWidget = FormField<bool>(
          initialValue: boolValue,
          builder: (state) {
            bool isSelected = state.value ?? false;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    state.didChange(!isSelected);
                    setState(() => formValues[key] = !isSelected);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.5)
                            : colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: isSelected,
                          onChanged: (val) {
                            state.didChange(val);
                            setState(() => formValues[key] = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );
        break;

      case 'select':
        List<Map<String, dynamic>> options = [];
        if (field.containsKey('options')) {
          options = (field['options'] as List).cast<Map<String, dynamic>>();
        } else if (field['data'] is String) {
          // Using a Set to ensure unique values and prevent crashes from duplicate items
          var uniqueData = (field['data'] as String).split(',').map((e) => e.trim()).toSet().toList();
          options = uniqueData
              .map(
                (o) => {
                  'value': o,
                  'label_lang': {'en': o},
                },
              )
              .toList();
        }

        String? currentValue = value?.toString();
        if (currentValue != null &&
            !options.any((o) => o['value'].toString() == currentValue)) {
          currentValue = null;
        }

        fieldWidget = DropdownButtonFormField<String>(
          value: currentValue,
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: options.map((opt) {
            String optValue = opt['value'].toString();
            return DropdownMenuItem(
              value: optValue,
              child: Text(
                opt['label_lang'][currentLang] ?? optValue,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              formValues[key] = val;
            });
          },
          validator: (val) => isRequired && (val == null || val.isEmpty)
              ? "Required"
              : null,
        );
        break;

      case 'date':
      case 'calendar':
      case 'time':
        fieldWidget = FormField<String>(
          initialValue: value?.toString(),
          validator: (val) {
            if (isRequired && (val == null || val.isEmpty)) {
              return "Please select a ${type == 'time' ? 'time' : 'date'}";
            }
            if (key.contains('birth') && val != null && val.isNotEmpty) {
              try {
                DateTime selectedDate = DateTime.parse(val);
                if (selectedDate.isAfter(DateTime.now())) {
                  return "Birth date cannot be in the future";
                }
              } catch (_) {}
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    if (type == 'time') {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        final localizations = MaterialLocalizations.of(context);
                        String formatted = localizations.formatTimeOfDay(
                          picked,
                          alwaysUse24HourFormat: true,
                        );
                        state.didChange(formatted);
                        setState(() => formValues[key] = formatted);
                      }
                    } else {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: key.contains('birth')
                            ? DateTime.now()
                            : DateTime(2100),
                      );
                      if (picked != null) {
                        String formatted = picked.toIso8601String().split(
                          'T',
                        )[0];
                        state.didChange(formatted);
                        setState(() => formValues[key] = formatted);
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: label,
                      prefixIcon: Icon(icon, size: 20),
                      errorText: state.hasError ? state.errorText : null,
                    ),
                    child: Text(
                      state.value ??
                          (key.contains('birth')
                              ? "YYYY-MM-DD"
                              : "Select ${type == 'time' ? 'time' : 'date'}"),
                      style: TextStyle(
                        color: state.value == null
                            ? colorScheme.onSurfaceVariant.withOpacity(0.6)
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
        break;

      case 'object':
        // Specialized UI for seat_class configuration
        if (key == 'seat_class' && value is Map) {
          var availableClasses = List<String>.from(value['available_classes'] ?? []);
          var seatsByClass = Map<String, dynamic>.from(value['seats_by_class'] ?? {});

          fieldWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...seatsByClass.keys.map((classKey) {
                var classData = seatsByClass[classKey];
                String classLabel = classData['label_lang']?[currentLang] ?? classKey;
                bool isEnabled = availableClasses.contains(classKey);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? colorScheme.secondaryContainer.withOpacity(0.1)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEnabled
                          ? colorScheme.secondary.withOpacity(0.3)
                          : colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: isEnabled,
                        onChanged: (val) {
                          setState(() {
                            if (val) {
                              availableClasses.add(classKey);
                            } else {
                              availableClasses.remove(classKey);
                            }
                            formValues[key]['available_classes'] = availableClasses;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isEnabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              "Available Seats",
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: classData['available_seats'].toString(),
                          enabled: isEnabled,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            filled: true,
                            fillColor: isEnabled ? colorScheme.surface : Colors.transparent,
                          ),
                          onChanged: (val) {
                            int? seats = int.tryParse(val);
                            if (seats != null) {
                              formValues[key]['seats_by_class'][classKey]['available_seats'] = seats;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        } else {
          // Fallback for other object types
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
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Configuration Data: ${value.toString()}",
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }
        break;

      default:
        fieldWidget = ListTile(
          title: Text(label),
          subtitle: Text("Type: $type"),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: fieldWidget,
    );
  }
}
