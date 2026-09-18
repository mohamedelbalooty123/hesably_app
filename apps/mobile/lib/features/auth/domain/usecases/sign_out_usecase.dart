import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/app_failure.dart';
import '../repositories/auth_repository.dart';

@injectable
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppFailure, void>> call() async {
    return _repository.signOut();
  }
}
