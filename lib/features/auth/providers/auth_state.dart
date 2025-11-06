import 'package:equatable/equatable.dart';
import '../../../core/models/user.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  needsEmailVerification,
  authenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? message;
  final String? errorCode;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.message,
    this.errorCode,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    String? errorCode,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    message: message,
    errorCode: errorCode,
  );

  @override
  List<Object?> get props => [status, user?.id, message, errorCode];
}
