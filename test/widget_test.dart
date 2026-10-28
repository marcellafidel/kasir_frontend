import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_frontend/main.dart';

void main() {
  testWidgets('Aplikasi Noma dapat dibuka', (WidgetTester tester) async {
    await tester.pumpWidget(const KasirApp());

    expect(find.byType(KasirApp), findsOneWidget);
  });
}