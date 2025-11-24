# Development Guide

This guide is for developers who want to contribute to or modify the Freemail mobile app.

## Development Setup

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK (included with Flutter)
- IDE: VS Code or Android Studio
- Git

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Free-mail/app/frontend
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation** (if needed):
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                   # App entry point and root widget
├── models/                     # Data models
│   └── email_message.dart     # Email and attachment models
├── screens/                    # Full-page screens
│   ├── login_screen.dart      # Authentication screen
│   ├── home_screen.dart       # Main inbox/email list
│   ├── email_detail_screen.dart  # Single email view
│   ├── settings_screen.dart   # App settings
│   └── domains_screen.dart    # Domain management
├── services/                   # Business logic and API calls
│   ├── auth_service.dart      # Authentication logic
│   ├── email_service.dart     # Email API calls
│   └── storage_service.dart   # Local storage
├── widgets/                    # Reusable UI components
│   ├── email_list_item.dart   # Email list tile
│   └── compose_dialog.dart    # Email composition
└── utils/                      # Utilities and helpers
    ├── constants.dart         # App constants
    └── helpers.dart           # Helper functions
```

## Code Style

### Dart Style Guide

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

- Use `lowerCamelCase` for variables, functions, and parameters
- Use `UpperCamelCase` for classes and types
- Use `snake_case` for file names
- Prefer `const` constructors where possible
- Use trailing commas for better formatting

### Flutter Best Practices

1. **Widget Organization**:
   - Keep widgets small and focused
   - Extract reusable widgets
   - Use `const` constructors for performance

2. **State Management**:
   - Use Provider for app-wide state
   - Use StatefulWidget for local state
   - Minimize rebuilds with proper widget structure

3. **Async Code**:
   - Use `async`/`await` for asynchronous operations
   - Handle errors with try-catch
   - Show loading states during async operations

4. **Code Organization**:
   - Group imports: Flutter, packages, local
   - Keep files under 500 lines
   - Use meaningful names

## Development Workflow

### 1. Creating a New Feature

1. **Create a new branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Implement the feature**:
   - Create necessary models in `lib/models/`
   - Add service methods in `lib/services/`
   - Create UI in `lib/screens/` or `lib/widgets/`
   - Update constants if needed

3. **Test your changes**:
   ```bash
   flutter test
   flutter run
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add: your feature description"
   git push origin feature/your-feature-name
   ```

### 2. Adding a New Screen

Example: Adding a "Labels" screen

1. **Create the screen file**:
   ```dart
   // lib/screens/labels_screen.dart
   import 'package:flutter/material.dart';
   
   class LabelsScreen extends StatefulWidget {
     const LabelsScreen({super.key});
     
     @override
     State<LabelsScreen> createState() => _LabelsScreenState();
   }
   
   class _LabelsScreenState extends State<LabelsScreen> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('Labels')),
         body: const Center(child: Text('Labels Screen')),
       );
     }
   }
   ```

2. **Add navigation** (in home_screen.dart):
   ```dart
   Navigator.of(context).push(
     MaterialPageRoute(builder: (_) => const LabelsScreen()),
   );
   ```

### 3. Adding a New Service Method

Example: Adding a method to fetch labels

```dart
// lib/services/email_service.dart
Future<List<String>> fetchLabels() async {
  try {
    final response = await http.get(
      Uri.parse('$backendUrl/api/labels'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['labels'] ?? []);
    }
    
    return [];
  } catch (e) {
    print('Error fetching labels: $e');
    return [];
  }
}
```

### 4. Adding a New Model

Example: Creating a Label model

```dart
// lib/models/label.dart
class Label {
  final String id;
  final String name;
  final String color;
  
  Label({
    required this.id,
    required this.name,
    required this.color,
  });
  
  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}
```

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Writing Tests

Example widget test:

```dart
// test/widgets/email_list_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:freemail/widgets/email_list_item.dart';
import 'package:freemail/models/email_message.dart';

void main() {
  testWidgets('EmailListItem displays email info', (tester) async {
    final email = EmailMessage(
      id: '1',
      from: 'sender@example.com',
      to: 'recipient@example.com',
      subject: 'Test Subject',
      body: 'Test body',
      date: DateTime.now(),
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailListItem(
            email: email,
            onTap: () {},
          ),
        ),
      ),
    );
    
    expect(find.text('Test Subject'), findsOneWidget);
  });
}
```

## Debugging

### Using DevTools

1. **Start the app**:
   ```bash
   flutter run
   ```

2. **Open DevTools**:
   - Press `v` in the terminal, or
   - Run `flutter pub global activate devtools` then `devtools`

3. **Features**:
   - Widget Inspector: Inspect UI hierarchy
   - Performance: Analyze performance
   - Network: Monitor API calls
   - Logging: View console output

### Debug Print

Use `debugPrint()` for logging:

```dart
debugPrint('User logged in: $email');
```

### Breakpoints

In VS Code or Android Studio:
1. Click on the line number to set a breakpoint
2. Run the app in debug mode
3. App will pause at breakpoints

## API Integration

### Making API Calls

Always use the service classes for API calls:

```dart
// Good
final emailService = EmailService(backendUrl);
final emails = await emailService.fetchEmails();

// Bad - don't call APIs directly in UI
final response = await http.get(Uri.parse('...'));
```

### Error Handling

Always handle errors:

```dart
try {
  final result = await emailService.sendEmail(...);
  if (result) {
    // Success
  } else {
    // Failed
  }
} catch (e) {
  // Handle error
  debugPrint('Error: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}
```

## Performance Optimization

### 1. Use const Constructors

```dart
// Good
const Text('Hello')

// Bad
Text('Hello')
```

### 2. Avoid Unnecessary Rebuilds

```dart
// Good - widget doesn't rebuild
class MyWidget extends StatelessWidget {
  final String text;
  const MyWidget({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

// Bad - rebuilds unnecessarily
Widget buildText() {
  return Text('Hello');
}
```

### 3. Use ListView.builder

```dart
// Good - builds items on demand
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// Bad - builds all items upfront
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)
```

## Common Issues

### Issue: Hot Reload Not Working

**Solution**:
- Try hot restart (`R` in terminal)
- Check for syntax errors
- Restart the app completely

### Issue: Package Version Conflicts

**Solution**:
```bash
flutter pub upgrade
flutter clean
flutter pub get
```

### Issue: Build Failures

**Solution**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

## Contributing

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Ensure code passes `flutter analyze`
6. Submit a pull request

### Code Review Checklist

- [ ] Code follows style guidelines
- [ ] Changes are tested
- [ ] Documentation is updated
- [ ] No unnecessary dependencies added
- [ ] Performance is acceptable
- [ ] UI is responsive
- [ ] Error handling is complete

## Resources

### Flutter Resources
- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Widget Catalog](https://docs.flutter.dev/ui/widgets)

### Community
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Dev Community](https://dev.to/t/flutter)

## Next Steps

- Add unit tests for services
- Add integration tests
- Implement CI/CD pipeline
- Add more features (labels, filters, search)
- Improve offline support
- Add push notifications
