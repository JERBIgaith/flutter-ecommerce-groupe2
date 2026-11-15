/// User model representing user profile data
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? address;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'user',
    this.address,
    this.photoUrl,
  });

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'address': address,
      'photoUrl': photoUrl,
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String? ?? 'user',
      address: map['address'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? address,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
