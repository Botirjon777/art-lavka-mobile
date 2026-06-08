import 'package:artlavka_studio/app.dart';
import 'package:artlavka_studio/features/auth/login_page.dart';
import 'package:artlavka_studio/features/auth/otp_page.dart';
import 'package:artlavka_studio/features/onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // No backend configured → mock auth (OTP 123456); a fresh seller has no
  // designer profile, so the KYC gate routes them to onboarding.
  testWidgets('login → otp → onboarding gate (mock)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ArtLavkaStudioApp()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '901234567');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(OtpPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
  });
}
