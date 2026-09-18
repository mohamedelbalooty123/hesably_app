import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

@injectable
class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppFailure, AuthSession>> call(String phone, String otp) async {
    if (otp.trim().isEmpty || otp.trim().length < 6) {
      return const Left(ValidationFailure('Phone and OTP cannot be empty'));
    }
    return _repository.verifyOtp(phone.trim(), otp.trim());
  }
}
