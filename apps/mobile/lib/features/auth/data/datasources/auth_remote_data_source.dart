import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/entities/auth_session.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOtp(String phone);
  Future<AuthSession> verifyOtp(String phone, String otp);
  Future<AuthSession?> restoreSession();
  Future<void> signOut();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<void> sendOtp(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw AuthFailure(e.message, cause: e);
    } catch (e) {
      throw UnexpectedFailure(e.toString(), cause: e);
    }
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      final session = response.session;
      if (session == null || response.user == null) {
        throw const UnexpectedFailure('User not found after OTP verification');
      }

      // Check if business setup is required
      // MVP behavior: assume setup is required if no business is linked.
      // We will assume it's incomplete until we fetch the business.
      final isSetupComplete = await _checkBusinessSetup(response.user!.id);

      return AuthSession(
        userId: response.user!.id,
        phone: response.user!.phone ?? phone,
        isBusinessSetupComplete: isSetupComplete,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message, cause: e);
    } catch (e) {
      throw UnexpectedFailure(e.toString(), cause: e);
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      if (session != null && user != null) {
        final isSetupComplete = await _checkBusinessSetup(user.id);
        return AuthSession(
          userId: user.id,
          phone: user.phone ?? '',
          isBusinessSetupComplete: isSetupComplete,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Ignore sign out errors.
    }
  }

  Future<bool> _checkBusinessSetup(String userId) async {
    try {
      final response = await _supabase.from('businesses').select().limit(1).maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}
