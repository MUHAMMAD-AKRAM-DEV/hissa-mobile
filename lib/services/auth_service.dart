// ============================================================
//  lib/services/auth_service.dart  —  OTP + JWT + profile.
//  Goes in:  hissa_mobile/lib/services/auth_service.dart  (replace all)
//
//  Requires:  flutter pub add shared_preferences
//  The JWT + user are saved on the device, so you stay logged
//  in across restarts (token is valid 7 days).
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'api_client.dart';

class AppUser {
  final String id, phoneNumber, role;
  String? fullName;
  AppUser({required this.id, required this.phoneNumber, required this.role, this.fullName});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: (j['id'] ?? j['userId'] ?? '').toString(),
    phoneNumber: (j['phoneNumber'] ?? '').toString(),
    role: (j['role'] ?? 'investor').toString(),
    fullName: j['fullName'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'phoneNumber': phoneNumber, 'role': role, 'fullName': fullName};

  bool get isNew => fullName == null || fullName!.trim().isEmpty;
}

class AuthService {
  AppUser? currentUser;

  static const _kToken = 'hissa_token';
  static const _kUser = 'hissa_user';

  bool get isLoggedIn => apiClient.authToken != null;

  // Called once at startup: restore a saved session if there is one.
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kToken);
      final userJson = prefs.getString(_kUser);
      if (token == null || userJson == null) return false;
      apiClient.authToken = token;
      currentUser = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiClient.authToken != null) await prefs.setString(_kToken, apiClient.authToken!);
      if (currentUser != null) await prefs.setString(_kUser, jsonEncode(currentUser!.toJson()));
    } catch (_) {}
  }

  Future<void> requestOtp(String phone) async {
    if (useMock) return;
    await apiClient.postJson('/auth/otp/request', {'phoneNumber': phone.trim()});
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    if (useMock) {
      currentUser = AppUser(id: 'mock', phoneNumber: phone, role: 'investor', fullName: null);
      return true;
    }
    final res = await apiClient.postJson('/auth/otp/verify', {
      'phoneNumber': phone.trim(),
      'otp': otp.trim(),
    }) as Map<String, dynamic>;

    if (res['success'] == true && res['accessToken'] != null) {
      apiClient.authToken = res['accessToken'] as String;
      if (res['user'] is Map) {
        currentUser = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      }
      await _save();
      return true;
    }
    return false;
  }

  Future<void> updateProfile(String fullName) async {
    if (useMock) { currentUser?.fullName = fullName; return; }
    final res = await apiClient.patchJson('/auth/profile', {'fullName': fullName.trim()});
    if (res is Map && res['fullName'] != null) {
      currentUser?.fullName = res['fullName'] as String;
    } else {
      currentUser?.fullName = fullName.trim();
    }
    await _save();
  }

  Future<void> logout() async {
    apiClient.authToken = null;
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.remove(_kUser);
    } catch (_) {}
  }
}

final authService = AuthService();