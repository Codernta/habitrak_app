import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String themeMode;
  final bool remindersEnabled;
  final int currentStreak;
  final int totalCompletedHabits;

  const UserModel({
    required this.uid,
    this.email = '',
    this.displayName = '',
    this.photoUrl,
    this.isAnonymous = false,
    this.createdAt,
    this.lastLoginAt,
    this.themeMode = 'dark',
    this.remindersEnabled = true,
    this.currentStreak = 0,
    this.totalCompletedHabits = 0,
  });

  factory UserModel.fromFirebaseUser(
    User user, {
    String themeMode = 'dark',
    bool remindersEnabled = true,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? (user.isAnonymous ? 'Guest Habitraker' : 'Mindful Explorer'),
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      themeMode: themeMode,
      remindersEnabled: remindersEnabled,
      currentStreak: 0,
      totalCompletedHabits: 0,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    final preferences = data['preferences'] as Map<String, dynamic>? ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      themeMode: preferences['themeMode'] as String? ?? 'dark',
      remindersEnabled: preferences['remindersEnabled'] as bool? ?? true,
      currentStreak: (stats['currentStreak'] as num?)?.toInt() ?? 0,
      totalCompletedHabits: (stats['totalCompletedHabits'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
      'preferences': {
        'themeMode': themeMode,
        'remindersEnabled': remindersEnabled,
      },
      'stats': {
        'currentStreak': currentStreak,
        'totalCompletedHabits': totalCompletedHabits,
      },
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? themeMode,
    bool? remindersEnabled,
    int? currentStreak,
    int? totalCompletedHabits,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      themeMode: themeMode ?? this.themeMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      currentStreak: currentStreak ?? this.currentStreak,
      totalCompletedHabits: totalCompletedHabits ?? this.totalCompletedHabits,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        isAnonymous,
        createdAt,
        lastLoginAt,
        themeMode,
        remindersEnabled,
        currentStreak,
        totalCompletedHabits,
      ];
}
