import 'package:artlavka_client/app.dart';
import 'package:artlavka_client/features/auth/login_page.dart';
import 'package:artlavka_client/features/auth/otp_page.dart';
import 'package:artlavka_client/features/auth/profile_completion_page.dart';
import 'package:artlavka_client/features/auth/welcome_page.dart';
import 'package:artlavka_client/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // With no backend configured in tests, auth runs against MockAuthService:
  // code "123456" succeeds; a login user has no name → profile completion.
  testWidgets('auth flow: welcome → login → otp → profile → home', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ArtLavkaClientApp()));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);

    // Welcome → Login (the filled "Log in" button).
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    // Enter a valid UZ phone and request the code.
    await tester.enterText(find.byType(TextField).first, '901234567');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(OtpPage), findsOneWidget);

    // Enter the code into the first box — it distributes + auto-submits.
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileCompletionPage), findsOneWidget);

    // Complete the profile → unlocks home.
    await tester.enterText(find.byType(TextField).first, 'Test User');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('wrong OTP shows an error and stays on the OTP screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ArtLavkaClientApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton)); // Log in
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '901234567');
    await tester.tap(find.byType(FilledButton)); // send code
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(OtpPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Still on OTP, with an error surfaced.
    expect(find.byType(OtpPage), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
