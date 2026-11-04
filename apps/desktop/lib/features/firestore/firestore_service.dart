// User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
// User story: US-03 Student profile (Sprint 1, MVP)
// Requirements: FR-PROF-001, FR-PROF-002..008, FR-PROF-010
// Implemented here: Cloud Firestore data service for consent records, profiles, and lab activity

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentConsentRecord {
  final String noticeVersion;
  final String timestamp;
  final bool ageCheckPassed;

  const StudentConsentRecord({
    required this.noticeVersion,
    required this.timestamp,
    required this.ageCheckPassed,
  });

  factory StudentConsentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentConsentRecord(
      noticeVersion: data['noticeVersion'] as String? ?? '',
      timestamp: data['timestamp'] as String? ?? '',
      ageCheckPassed: data['ageCheckPassed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'noticeVersion': noticeVersion,
      'timestamp': timestamp,
      'ageCheckPassed': ageCheckPassed,
      // Strictly NO dateOfBirth or dob per FR-PROF-010
    };
  }
}

class StudentProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? college;
  final String? course;
  final String? academicYear;
  final List<String> interests;

  const StudentProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.college,
    this.course,
    this.academicYear,
    this.interests = const [],
  });

  factory StudentProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      college: data['college'] as String?,
      course: data['course'] as String?,
      academicYear: data['academicYear'] as String?,
      interests: List<String>.from(data['interests'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      if (college != null) 'college': college,
      if (course != null) 'course': course,
      if (academicYear != null) 'academicYear': academicYear,
      'interests': interests,
      'updatedAt': FieldValue.serverTimestamp(),
      // Strictly NO dateOfBirth, phone, or address per FR-PROF-003
    };
  }
}

class FirestoreService {
  final FirebaseFirestore? _customFirestore;

  FirestoreService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get consentsRef => _firestore.collection('consents');

  /// Records student consent per FR-PROF-001 and FR-PROF-010.
  Future<void> recordConsent({
    required String uid,
    required String noticeVersion,
    required String timestamp,
    required bool ageCheckPassed,
  }) async {
    final record = StudentConsentRecord(
      noticeVersion: noticeVersion,
      timestamp: timestamp,
      ageCheckPassed: ageCheckPassed,
    );

    await consentsRef.doc(uid).set(record.toFirestore(), SetOptions(merge: true));
    await usersRef.doc(uid).collection('consent').doc('current').set(
      record.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Fetches student consent record.
  Future<StudentConsentRecord?> getConsent(String uid) async {
    final doc = await consentsRef.doc(uid).get();
    if (!doc.exists) return null;
    return StudentConsentRecord.fromFirestore(doc);
  }

  /// Saves student profile.
  Future<void> saveProfile(StudentProfile profile) async {
    await usersRef.doc(profile.uid).set(profile.toFirestore(), SetOptions(merge: true));
  }

  /// Fetches student profile.
  Future<StudentProfile?> getProfile(String uid) async {
    final doc = await usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return StudentProfile.fromFirestore(doc);
  }
}

