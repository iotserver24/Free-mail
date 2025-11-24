import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/email_message.dart';

class EmailService {
  final String backendUrl;

  EmailService(this.backendUrl);

  Future<List<EmailMessage>> fetchEmails({
    String folder = 'inbox',
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/messages?folder=$folder&page=$page&perPage=$perPage'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> emailsJson = data['messages'] ?? data['data'] ?? [];
        
        return emailsJson
            .map((json) => EmailMessage.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching emails: $e');
      return [];
    }
  }

  Future<EmailMessage?> fetchEmailById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/messages/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EmailMessage.fromJson(data);
      }
      
      return null;
    } catch (e) {
      print('Error fetching email: $e');
      return null;
    }
  }

  Future<bool> sendEmail({
    required String from,
    required String to,
    required String subject,
    required String body,
    List<String>? cc,
    List<String>? bcc,
    List<Map<String, String>>? attachments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/messages'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'from': from,
          'to': to,
          'subject': subject,
          'body': body,
          if (cc != null && cc.isNotEmpty) 'cc': cc.join(','),
          if (bcc != null && bcc.isNotEmpty) 'bcc': bcc.join(','),
          if (attachments != null && attachments.isNotEmpty) 
            'attachments': attachments,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  Future<bool> deleteEmail(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/messages/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting email: $e');
      return false;
    }
  }

  Future<List<String>> fetchDomains() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/domains'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> domainsJson = data['domains'] ?? data['data'] ?? [];
        
        return domainsJson
            .map((json) => json['name'] as String? ?? json['domain'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching domains: $e');
      return [];
    }
  }

  Future<bool> addDomain(String domain) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/domains'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': domain,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding domain: $e');
      return false;
    }
  }
}
