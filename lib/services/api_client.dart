// ============================================================
//  lib/services/api_client.dart  —  Thin HTTP wrapper.
//  Goes in:  hissa_mobile/lib/services/api_client.dart   (replace all)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiClient {
  String? authToken; // set after login

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  Future<dynamic> getJson(String path) async {
    final res = await http.get(Uri.parse('$apiBaseUrl$path'), headers: _headers);
    _check(res, 'GET', path);
    return jsonDecode(res.body);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$apiBaseUrl$path'), headers: _headers, body: jsonEncode(body));
    _check(res, 'POST', path);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('$apiBaseUrl$path'), headers: _headers, body: jsonEncode(body));
    _check(res, 'PATCH', path);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  Future<dynamic> deleteJson(String path) async {
    final res = await http.delete(Uri.parse('$apiBaseUrl$path'), headers: _headers);
    _check(res, 'DELETE', path);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  // Multipart upload (used by KYC).
  // files: fieldName -> (bytes, filename)
  Future<dynamic> postMultipart(
      String path,
      Map<String, String> fields,
      Map<String, ({List<int> bytes, String filename})> files,
      ) async {
    final req = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl$path'));
    if (authToken != null) req.headers['Authorization'] = 'Bearer $authToken';
    req.fields.addAll(fields);
    files.forEach((field, f) {
      req.files.add(http.MultipartFile.fromBytes(field, f.bytes, filename: f.filename));
    });
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _check(res, 'POST', path);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  void _check(http.Response res, String method, String path) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$method $path failed (${res.statusCode}): ${res.body}');
    }
  }
}

final apiClient = ApiClient();