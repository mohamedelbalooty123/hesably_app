import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesably/app/app.dart';
import 'package:hesably/app/router/app_router.dart';
import 'package:hesably/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hesably/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:hesably/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:hesably/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:hesably/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hesably/core/error/app_failure.dart';
import 'package:hesably/features/auth/domain/entities/auth_session.dart';

class DummySendOtpUseCase implements SendOtpUseCase {
  @override
  Future<Either<AppFailure, void>> call(String phone) async => const Right(null);
}
class DummyVerifyOtpUseCase implements VerifyOtpUseCase {
  @override
  Future<Either<AppFailure, AuthSession>> call(String phone, String otp) async => const Right(AuthSession(userId: '1', phone: '1', isBusinessSetupComplete: true));
}
class DummyRestoreSessionUseCase implements RestoreSessionUseCase {
  @override
  Future<Either<AppFailure, AuthSession?>> call() async => const Right(AuthSession(userId: '1', phone: '1', isBusinessSetupComplete: true));
}
class DummySignOutUseCase implements SignOutUseCase {
  @override
  Future<Either<AppFailure, void>> call() async => const Right(null);
}

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    final mockSend = DummySendOtpUseCase();
    final mockVerify = DummyVerifyOtpUseCase();
    final mockRestore = DummyRestoreSessionUseCase();
    final mockSignOut = DummySignOutUseCase();
    
    final authCubit = AuthCubit(mockRestore, mockSend, mockVerify, mockSignOut);

    await tester.pumpWidget(HesablyApp(authCubit: authCubit, router: AppRouter(authCubit)));
    await tester.pumpAndSettle();
  }

  testWidgets('app boots to the home shell with the bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('الرئيسية'), findsWidgets);
  });

  testWidgets('navigation switches between the four tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('المعاملات'));
    await tester.pumpAndSettle();
    expect(find.text('المعاملات'), findsWidgets);

    await tester.tap(find.text('التقارير'));
    await tester.pumpAndSettle();
    expect(find.text('التقارير'), findsWidgets);

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsWidgets);
  });
}
