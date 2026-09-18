import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final otp = _otpController.text.trim();
      context.read<AuthCubit>().verifyOtp(otp);
    }
  }

  void _resendOtp(String phone) {
    context.read<AuthCubit>().sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رمز التحقق'), // Hardcoded for MVP as per request context
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          
          String phone = '';
          int cooldown = 0;
          
          if (state is AuthOtpSent) {
            phone = state.phone;
            cooldown = state.resendCooldownSeconds;
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أدخل رمز التحقق',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم إرسال رسالة نصية قصيرة تحتوي على الرمز إلى $phone',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'الرمز (6 أرقام)',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرمز مطلوب';
                        }
                        if (value.trim().length < 6) {
                          return 'يجب أن يتكون الرمز من 6 أرقام';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('تحقق'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: (isLoading || cooldown > 0)
                          ? null
                          : () => _resendOtp(phone),
                      child: Text(
                        cooldown > 0
                            ? 'إعادة إرسال الرمز ($cooldown ثانية)'
                            : 'إعادة إرسال الرمز',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
