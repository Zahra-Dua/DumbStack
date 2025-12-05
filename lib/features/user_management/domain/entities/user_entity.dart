import 'package:equatable/equatable.dart';

abstract class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String userType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [uid, name, email, userType, createdAt, updatedAt];
}

class ParentUser extends UserEntity {
  final List<String> childrenIds;

  const ParentUser({
    required super.uid,
    required super.name,
    required super.email,
    required super.userType,
    required super.createdAt,
    required super.updatedAt,
    required this.childrenIds,
  });

  @override
  List<Object?> get props => [...super.props, childrenIds];
}

class ChildUser extends UserEntity {
  final int age;
  final String gender;
  final List<String> hobbies;

  const ChildUser({
    required super.uid,
    required super.name,
    required super.email,
    required super.userType,
    required super.createdAt,
    required super.updatedAt,
    required this.age,
    required this.gender,
    required this.hobbies,
  });

  @override
  List<Object?> get props => [...super.props, age, gender, hobbies];
}
