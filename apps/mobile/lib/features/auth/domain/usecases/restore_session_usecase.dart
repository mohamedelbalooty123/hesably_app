import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

@injectable
class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppFailure, AuthSession?>> call() async {
    return _repository.restoreSession();
  }
}
