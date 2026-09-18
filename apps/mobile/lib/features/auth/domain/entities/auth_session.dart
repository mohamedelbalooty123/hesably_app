import 'package:equatable/equatable.dart';

/// Represents an authenticated user session in the application.
class AuthSession extends Equatable {
  const AuthSession({
    required this.userId,
    required this.phone,
    required this.isBusinessSetupComplete,
  });

  final String userId;
  final String phone;
  final bool isBusinessSetupComplete;

  @override
  List<Object?> get props => [userId, phone, isBusinessSetupComplete];
}
