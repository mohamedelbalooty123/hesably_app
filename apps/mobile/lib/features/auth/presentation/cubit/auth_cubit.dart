import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_state.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._restoreSessionUseCase,
    this._sendOtpUseCase,
    this._verifyOtpUseCase,
    this._signOutUseCase,
  ) : super(const AuthInitial());

  final RestoreSessionUseCase _restoreSessionUseCase;
  final SendOtpUseCase _sendOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final SignOutUseCase _signOutUseCase;

  Timer? _cooldownTimer;
  static const int _maxCooldownSeconds = 60;
  String? _currentPhone;

  Future<void> restoreSession() async {
    emit(const AuthLoading());
    final result = await _restoreSessionUseCase();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (session) {
        if (session != null) {
          emit(AuthAuthenticated(session));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> sendOtp(String phone) async {
    // Only allow sending if not in cooldown
    if (state is AuthOtpSent) {
      final currentCooldown = (state as AuthOtpSent).resendCooldownSeconds;
      if (currentCooldown > 0) return;
    }

    _currentPhone = phone;
    emit(const AuthLoading());

    final result = await _sendOtpUseCase(phone);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) {
        _startCooldown();
      },
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (_currentPhone == null) return;
    
    // Save current cooldown state before entering loading
    int currentCooldown = 0;
    if (state is AuthOtpSent) {
      currentCooldown = (state as AuthOtpSent).resendCooldownSeconds;
    }
    
    emit(const AuthLoading());
    
    final result = await _verifyOtpUseCase(_currentPhone!, otp);
    result.fold(
      (failure) {
        emit(AuthFailure(failure.message));
        // Restore OTP sent state so user can retry or wait for cooldown
        emit(AuthOtpSent(
          phone: _currentPhone!,
          resendCooldownSeconds: currentCooldown,
        ));
      },
      (session) {
        _cancelCooldown();
        emit(AuthAuthenticated(session));
      },
    );
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    await _signOutUseCase();
    emit(const AuthUnauthenticated());
  }

  void _startCooldown() {
    _cancelCooldown();
    emit(AuthOtpSent(
      phone: _currentPhone!,
      resendCooldownSeconds: _maxCooldownSeconds,
    ));

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is AuthOtpSent) {
        final currentSeconds = (state as AuthOtpSent).resendCooldownSeconds;
        if (currentSeconds > 0) {
          emit(AuthOtpSent(
            phone: _currentPhone!,
            resendCooldownSeconds: currentSeconds - 1,
          ));
        } else {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _cancelCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  @override
  Future<void> close() {
    _cancelCooldown();
    return super.close();
  }
}
