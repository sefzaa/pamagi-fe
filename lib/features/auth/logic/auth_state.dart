abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
class AuthOtpSent extends AuthState {}

class AuthOtpVerified extends AuthState {
  final String resetToken;
  AuthOtpVerified(this.resetToken);
}

class AuthPasswordResetSuccess extends AuthState {}