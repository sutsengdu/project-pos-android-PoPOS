import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  String baseUrl;
  String? _token;
  late http.Client _client;
  
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? dotenv.get('API_URL', fallback: 'http://192.168.99.14/project-pos/backend/public/api') {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    _client = IOClient(ioClient);
  }

  void setToken(String? token) {
    _token = token;
  }

  void setBaseUrl(String url) {
    baseUrl = url;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<http.Response> ping() async {
    return await _client.get(
      Uri.parse('$baseUrl/ping'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    final combinedHeaders = {..._headers, ...?headers};
    return await _client.post(
      uri,
      headers: combinedHeaders,
      body: jsonEncode(data),
    );
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');
    final combinedHeaders = {..._headers, ...?headers};
    return await _client.get(
      uri,
      headers: combinedHeaders,
    );
  }
}
