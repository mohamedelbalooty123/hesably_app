import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_session.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent({
    required this.phone,
    required this.resendCooldownSeconds,
  });

  final String phone;
  final int resendCooldownSeconds;

  @override
  List<Object?> get props => [phone, resendCooldownSeconds];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
