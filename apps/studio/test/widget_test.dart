import 'package:artlavka_studio/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('foundation shell renders the brand', (tester) async {
    await tester.pumpWidget(const ArtLavkaStudioApp());
    await tester.pumpAndSettle();
    expect(find.text('Studio'), findsOneWidget);
  });
}
