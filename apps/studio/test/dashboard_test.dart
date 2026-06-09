import 'package:artlavka_core/artlavka_core.dart';
import 'package:artlavka_studio/bootstrap/core_providers.dart';
import 'package:artlavka_studio/features/designs/designs_page.dart';
import 'package:artlavka_studio/l10n/l10n.dart';
import 'package:artlavka_studio/ui/async_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Design _design() => Design(
  id: 'd1',
  designerId: 'u1',
  title: 'Pixel Cat',
  previewUrl: '',
  printFilePath: 'print-files/x.png',
  status: DesignStatus.pending,
  createdAt: DateTime(2026),
);

class _FakeDesigns extends DesignRepository {
  _FakeDesigns(this.items) : super(ApiClient(tokenStore: TokenStore()));
  final List<Design> items;

  @override
  Future<Result<List<Design>>> myDesigns({
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) async => Success(items);
}

Widget _host(Widget child, List<Design> designs) => ProviderScope(
  overrides: [
    designRepositoryProvider.overrideWithValue(_FakeDesigns(designs)),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('designs page shows empty state', (tester) async {
    await tester.pumpWidget(_host(const DesignsPage(), const []));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('designs page lists a design with its status', (tester) async {
    await tester.pumpWidget(_host(const DesignsPage(), [_design()]));
    await tester.pumpAndSettle();
    expect(find.text('Pixel Cat'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
  });
}
