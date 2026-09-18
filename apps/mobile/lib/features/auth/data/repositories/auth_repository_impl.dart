import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Either<AppFailure, void>> sendOtp(String phone) async {
    try {
      await _remoteDataSource.sendOtp(phone);
      return const Right(null);
    } on AppFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString(), cause: e));
    }
  }

  @override
  Future<Either<AppFailure, AuthSession>> verifyOtp(
      String phone, String otp) async {
    try {
      final session = await _remoteDataSource.verifyOtp(phone, otp);
      return Right(session);
    } on AppFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString(), cause: e));
    }
  }

  @override
  Future<Either<AppFailure, AuthSession?>> restoreSession() async {
    try {
      final session = await _remoteDataSource.restoreSession();
      return Right(session);
    } on AppFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString(), cause: e));
    }
  }

  @override
  Future<Either<AppFailure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString(), cause: e));
    }
  }
}
