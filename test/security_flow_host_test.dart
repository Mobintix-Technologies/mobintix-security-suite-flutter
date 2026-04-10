import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobintix_security_suite/mobintix_security_suite.dart';
import 'package:mobintix_ui_kit/mobintix_ui_kit.dart';

void main() {
  testWidgets('SecurityFlowHost builds OTP UI for otp step', (tester) async {
    const flow = SecurityFlowResponse(
      schemaVersion: 1,
      flowId: 't',
      step: SecurityFlowStepId.otp,
      config: OtpConfig(title: 'Enter code', otpLength: 4),
    );

    await tester.pumpWidget(
      AppThemeScope(
        theme: AppTheme.light(),
        child: MaterialApp(
          home: Scaffold(
            body: SecurityFlowHost(
              flow: flow,
              actions: SecurityFlowActions(
                onOtpComplete: (o) async {},
                onOtpResend: () async {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Enter code'), findsOneWidget);
  });

  testWidgets('unknown step routes to customStepBuilder', (tester) async {
    const flow = SecurityFlowResponse(
      schemaVersion: 1,
      step: SecurityFlowStepId.unknown,
      config: CustomStepConfig(data: {'title': 'Custom'}),
    );

    await tester.pumpWidget(
      AppThemeScope(
        theme: AppTheme.light(),
        child: MaterialApp(
          home: Scaffold(
            body: SecurityFlowHost(
              flow: flow,
              actions: const SecurityFlowActions(),
              customStepBuilder: (f) => const Text('Custom handled'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Custom handled'), findsOneWidget);
  });

  testWidgets('unknown step without builder shows ErrorState', (tester) async {
    const flow = SecurityFlowResponse(
      schemaVersion: 1,
      step: SecurityFlowStepId.done,
      config: CustomStepConfig(),
    );

    await tester.pumpWidget(
      AppThemeScope(
        theme: AppTheme.light(),
        child: const MaterialApp(
          home: Scaffold(
            body: SecurityFlowHost(
              flow: flow,
              actions: SecurityFlowActions(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Unsupported step'), findsOneWidget);
  });
}
