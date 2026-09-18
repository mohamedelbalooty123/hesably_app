import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/auth_session.dart';

/// Repository interface for authentication operations.
abstract class AuthRepository {
  /// Sends an OTP to the given phone number.
  Future<Either<AppFailure, void>> sendOtp(String phone);

  /// Verifies the OTP sent to the phone number.
  Future<Either<AppFailure, AuthSession>> verifyOtp(String phone, String otp);

  /// Restores the session if the user is already authenticated.
  Future<Either<AppFailure, AuthSession?>> restoreSession();

  /// Signs the user out.
  Future<Either<AppFailure, void>> signOut();
}
