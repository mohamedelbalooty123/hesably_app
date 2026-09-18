import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hesably/core/error/app_failure.dart' as err;
import 'package:hesably/features/auth/domain/entities/auth_session.dart';
import 'package:hesably/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:hesably/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:hesably/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:hesably/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:hesably/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:hesably/features/auth/presentation/cubit/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockRestoreSessionUseCase extends Mock implements RestoreSessionUseCase {}
class MockSendOtpUseCase extends Mock implements SendOtpUseCase {}
class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  late AuthCubit authCubit;
  late MockRestoreSessionUseCase mockRestoreSession;
  late MockSendOtpUseCase mockSendOtp;
  late MockVerifyOtpUseCase mockVerifyOtp;
  late MockSignOutUseCase mockSignOut;

  setUp(() {
    mockRestoreSession = MockRestoreSessionUseCase();
    mockSendOtp = MockSendOtpUseCase();
    mockVerifyOtp = MockVerifyOtpUseCase();
    mockSignOut = MockSignOutUseCase();
    authCubit = AuthCubit(
      mockRestoreSession,
      mockSendOtp,
      mockVerifyOtp,
      mockSignOut,
    );
  });

  tearDown(() {
    authCubit.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authCubit.state, equals(const AuthInitial()));
  });

  test('emits [AuthLoading, AuthAuthenticated] when restoreSession succeeds with a session', () async {
    when(() => mockRestoreSession()).thenAnswer(
      (_) async => const Right(AuthSession(userId: '1', phone: '123', isBusinessSetupComplete: true)),
    );

    final expectedStates = [
      const AuthLoading(),
      const AuthAuthenticated(AuthSession(userId: '1', phone: '123', isBusinessSetupComplete: true)),
    ];

    expectLater(authCubit.stream, emitsInOrder(expectedStates));
    await authCubit.restoreSession();
  });

  test('emits [AuthLoading, AuthUnauthenticated] when restoreSession returns null session', () async {
    when(() => mockRestoreSession()).thenAnswer(
      (_) async => const Right(null),
    );

    final expectedStates = [
      const AuthLoading(),
      const AuthUnauthenticated(),
    ];

    expectLater(authCubit.stream, emitsInOrder(expectedStates));
    await authCubit.restoreSession();
  });

  test('emits [AuthLoading, AuthUnauthenticated] when restoreSession fails', () async {
    when(() => mockRestoreSession()).thenAnswer(
      (_) async => const Left(err.AuthFailure('Failed')),
    );

    final expectedStates = [
      const AuthLoading(),
      const AuthUnauthenticated(),
    ];

    expectLater(authCubit.stream, emitsInOrder(expectedStates));
    await authCubit.restoreSession();
  });

  test('emits [AuthLoading, AuthOtpSent] when sendOtp succeeds', () async {
    when(() => mockSendOtp('123')).thenAnswer(
      (_) async => const Right(null),
    );

    final expectedStates = [
      const AuthLoading(),
      const AuthOtpSent(phone: '123', resendCooldownSeconds: 60),
    ];

    expectLater(authCubit.stream, emitsInOrder(expectedStates));
    await authCubit.sendOtp('123');
  });

  test('emits [AuthLoading, AuthFailure] when sendOtp fails', () async {
    when(() => mockSendOtp('123')).thenAnswer(
      (_) async => const Left(err.AuthFailure('Invalid phone')),
    );

    final expectedStates = [
      const AuthLoading(),
      const AuthFailure('Invalid phone'),
    ];

    expectLater(authCubit.stream, emitsInOrder(expectedStates));
    await authCubit.sendOtp('123');
  });

  test('emits [AuthLoading, AuthAuthenticated] when verifyOtp succeeds', () async {
    // Setup current phone
    when(() => mockSendOtp('123')).thenAnswer((_) async => const Right(null));
    await authCubit.sendOtp('123');

    when(() => mockVerifyOtp('123', '123456')).thenAnswer(
      (_) async => const Right(AuthSession(userId: '1', phone: '123', isBusinessSetupComplete: false)),
    );

    final expectedStates = [
      const AuthLoading(),
      const AuthAuthenticated(AuthSession(userId: '1', phone: '123', isBusinessSetupComplete: false)),
    ];

    expectLater(authCubit.stream, emitsInOrder(expectedStates));
    await authCubit.verifyOtp('123456');
  });

  test('emits [AuthLoading, AuthFailure, AuthOtpSent] when verifyOtp fails', () async {
    // Setup current phone
    when(() => mockSendOtp('123')).thenAnswer((_) async => const Right(null));
    await authCubit.sendOtp('123');

    when(() => mockVerifyOtp('123', '123456')).thenAnswer(
      (_) async => const Left(err.AuthFailure('Invalid code')),
    );

    final expectedStates = [
      const AuthLoading(),
      const AuthFailure('Invalid code'),
      const AuthOtpSent(phone: '123', resendCooldownSeconds: 60),
    ];

    expectLater(authCubit.stream, emitsInOrder(expectedStates));
    await authCubit.verifyOtp('123456');
  });
}
