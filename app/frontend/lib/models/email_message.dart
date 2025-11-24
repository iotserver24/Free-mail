class EmailMessage {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime date;
  final bool isRead;
  final bool isStarred;
  final List<String>? cc;
  final List<String>? bcc;
  final List<EmailAttachment>? attachments;
  final String? inReplyTo;
  final String? folder;

  EmailMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.date,
    this.isRead = false,
    this.isStarred = false,
    this.cc,
    this.bcc,
    this.attachments,
    this.inReplyTo,
    this.folder,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['_id'] ?? json['id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      subject: json['subject'] ?? '(No Subject)',
      body: json['body'] ?? json['text'] ?? json['html'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      isRead: json['isRead'] ?? json['read'] ?? false,
      isStarred: json['isStarred'] ?? json['starred'] ?? false,
      cc: json['cc'] != null 
          ? (json['cc'] is String 
              ? (json['cc'] as String).split(',').map((e) => e.trim()).toList()
              : List<String>.from(json['cc']))
          : null,
      bcc: json['bcc'] != null
          ? (json['bcc'] is String
              ? (json['bcc'] as String).split(',').map((e) => e.trim()).toList()
              : List<String>.from(json['bcc']))
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => EmailAttachment.fromJson(a))
              .toList()
          : null,
      inReplyTo: json['inReplyTo'] ?? json['in_reply_to'],
      folder: json['folder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'subject': subject,
      'body': body,
      'date': date.toIso8601String(),
      'isRead': isRead,
      'isStarred': isStarred,
      if (cc != null) 'cc': cc,
      if (bcc != null) 'bcc': bcc,
      if (attachments != null) 
        'attachments': attachments!.map((a) => a.toJson()).toList(),
      if (inReplyTo != null) 'inReplyTo': inReplyTo,
      if (folder != null) 'folder': folder,
    };
  }

  String get preview {
    final text = body.replaceAll(RegExp(r'<[^>]*>'), ''); // Strip HTML tags
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  String get senderName {
    // Extract name from "Name <email@example.com>" format
    final match = RegExp(r'^(.*?)\s*<').firstMatch(from);
    return match?.group(1) ?? from.split('@').first;
  }

  String get senderEmail {
    // Extract email from "Name <email@example.com>" format
    final match = RegExp(r'<(.+?)>').firstMatch(from);
    return match?.group(1) ?? from;
  }
}

class EmailAttachment {
  final String id;
  final String filename;
  final String contentType;
  final int size;
  final String? url;

  EmailAttachment({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.size,
    this.url,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      id: json['_id'] ?? json['id'] ?? '',
      filename: json['filename'] ?? json['name'] ?? 'attachment',
      contentType: json['contentType'] ?? json['mimeType'] ?? 'application/octet-stream',
      size: json['size'] ?? 0,
      url: json['url'] ?? json['downloadUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'contentType': contentType,
      'size': size,
      if (url != null) 'url': url,
    };
  }

  String get sizeString {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  bool get isImage {
    return contentType.startsWith('image/');
  }

  bool get isPdf {
    return contentType == 'application/pdf';
  }
}
