class UserModel {
  final String uid;
  final String nama;
  final String email;
  final bool setupCompleted;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.setupCompleted,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      nama: map["nama"] ?? "",
      email: map["email"] ?? "",
      setupCompleted: map["setupCompleted"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "nama": nama,
      "email": email,
      "setupCompleted": setupCompleted,
    };
  }
}