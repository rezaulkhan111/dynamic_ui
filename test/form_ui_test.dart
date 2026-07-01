import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_ui/screens/form_screen.dart';

void main() {
  testWidgets('Form Screen Loads and Validates Fields', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: FormScreen()));

    // Wait for the JSON data to load
    await tester.pumpAndSettle();

    // Verify that the Form Title is displayed (from JSON item_name)
    expect(find.text('Ticket: Delhi > Bangalore'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify that the "Save Changes" button exists
    expect(find.text('Save Changes'), findsOneWidget);

    // Try to submit without filling required fields
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify that validation errors appear
    expect(find.text('This field is required'), findsAtLeastNWidgets(1));

    // Fill in the passenger name (First TextFormField)
    await tester.enterText(find.byType(TextFormField).first, 'John Doe');
    await tester.pump();
    
    // Check if clicking Save Changes again reduces error count or works
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    
    // The "This field is required" error for name should be gone, 
    // but others remain.
  });

  testWidgets('Conditional fields appear/disappear correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: FormScreen()));
    await tester.pumpAndSettle();

    // 1. Initial State: schedule_type is 'recurring' by default in JSON
    // 'Departure day (recurring)' should be visible
    expect(find.text('Departure day (recurring)'), findsOneWidget);
    // 'Departure date (specific)' should NOT be visible
    expect(find.text('Departure date (specific)'), findsNothing);

    // 2. Change schedule_type to 'specific_dates'
    // Find the dropdown for schedule type
    final dropdownFinder = find.byWidgetPredicate((widget) => 
      widget is DropdownButtonFormField<String> && 
      (widget.decoration.labelText == 'Select schedule type')
    );
    
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Select 'Specific dates (calendar)'
    await tester.tap(find.text('Specific dates (calendar)').last);
    await tester.pumpAndSettle();

    // 3. Verify visibility change
    // 'Departure day (recurring)' should now be HIDDEN
    expect(find.text('Departure day (recurring)'), findsNothing);
    // 'Departure date (specific)' should now be VISIBLE
    expect(find.text('Departure date (specific)'), findsOneWidget);
  });
}
