class UserInfo {
  final int? id;
  final String name;
  final String email;

  UserInfo({this.id, required this.name, required this.email});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email};
  }

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(id: map['id'], name: map['name'], email: map['email']);
  }
}
