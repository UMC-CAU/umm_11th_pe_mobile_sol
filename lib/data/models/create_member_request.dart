class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });
  final String email;
  final String password;
  final String nickname;
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}

class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });
  final int memberId;
  final String email;
  final String nickname;
  factory SignUpResult.fromJson(Map<String, dynamic> json) => SignUpResult(
    memberId: (json['memberId'] as num).toInt(),
    email: json['email'] as String,
    nickname: json['nickname'] as String,
  );
}
