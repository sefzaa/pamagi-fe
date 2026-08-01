import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/auth/data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit(this.repository) : super(AuthInitial());

  String _cleanErrorMessage(String error) {
    if (error.startsWith('Exception: ')) {
      return error.replaceFirst('Exception: ', '');
    }
    return error;
  }

  Future<void> loginUser(String identifier, String password) async {
    emit(AuthLoading());
    try {
      await repository.login(identifier, password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_cleanErrorMessage(e.toString()))); // Bersihkan error
    }
  }

  Future<void> registerUser(Map<String, dynamic> requestBody) async {
    emit(AuthLoading());
    try {
      await repository.register(requestBody);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_cleanErrorMessage(e.toString()))); // Bersihkan error
    }
  }

  Future<void> updateProfile(Map<String, dynamic> requestBody) async {
    emit(AuthLoading());
    try {
      await repository.updateProfile(requestBody);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // --- FORGOT PASSWORD FLOW ---

  Future<void> requestForgotPasswordOTP(String email) async {
    emit(AuthLoading());
    try {
      await repository.requestForgotPasswordOTP(email);
      emit(AuthOtpSent()); // Picu perpindahan ke layar Input OTP
    } catch (e) {
      emit(AuthFailure(_cleanErrorMessage(e.toString())));
    }
  }

  Future<void> verifyOTP(String email, String otp) async {
    emit(AuthLoading());
    try {
      final resetToken = await repository.verifyOTP(email, otp);
      emit(AuthOtpVerified(resetToken)); // Picu perpindahan ke layar Input Password Baru
    } catch (e) {
      emit(AuthFailure(_cleanErrorMessage(e.toString())));
    }
  }

  Future<void> resetPassword(String email, String resetToken, String newPassword) async {
    emit(AuthLoading());
    try {
      await repository.resetPassword(email, resetToken, newPassword);
      emit(AuthPasswordResetSuccess()); // Berhasil total!
    } catch (e) {
      emit(AuthFailure(_cleanErrorMessage(e.toString())));
    }
  }
}