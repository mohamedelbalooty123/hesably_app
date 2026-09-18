import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/app_failure.dart';
import '../repositories/auth_repository.dart';

@injectable
class SendOtpUseCase {
  const SendOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppFailure, void>> call(String phone) async {
    // Basic validation before sending to data layer
    if (phone.trim().isEmpty) {
      return const Left(ValidationFailure('Phone number cannot be empty'));
    }
    return _repository.sendOtp(phone.trim());
  }
}
