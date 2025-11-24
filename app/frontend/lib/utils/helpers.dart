import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format date for email list (e.g., "Nov 24" or "2:30 PM")
  static String formatEmailDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return DateFormat('h:mm a').format(date);
    } else if (now.year == date.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
  
  /// Format date for email detail (e.g., "Nov 24, 2024 2:30 PM")
  static String formatDetailDate(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }
  
  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
  
  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}

class EmailUtils {
  /// Extract name from email address (e.g., "John Doe <john@example.com>" -> "John Doe")
  static String extractName(String emailAddress) {
    final match = RegExp(r'^(.*?)\s*<').firstMatch(emailAddress);
    return match?.group(1) ?? emailAddress.split('@').first;
  }
  
  /// Extract email from email address (e.g., "John Doe <john@example.com>" -> "john@example.com")
  static String extractEmail(String emailAddress) {
    final match = RegExp(r'<(.+?)>').firstMatch(emailAddress);
    return match?.group(1) ?? emailAddress;
  }
  
  /// Validate email address
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Strip HTML tags from text
  static String stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
  
  /// Get email preview (first N characters without HTML)
  static String getPreview(String body, {int maxLength = 100}) {
    final text = stripHtml(body);
    return text.length > maxLength 
        ? '${text.substring(0, maxLength)}...' 
        : text;
  }
}

class FileUtils {
  /// Format file size (e.g., "1.5 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Get file extension
  static String getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
  
  /// Check if file is an image
  static bool isImage(String contentType) {
    return contentType.startsWith('image/');
  }
  
  /// Check if file is a PDF
  static bool isPdf(String contentType) {
    return contentType == 'application/pdf';
  }
  
  /// Check if file is a document
  static bool isDocument(String contentType) {
    return contentType.contains('document') ||
        contentType.contains('word') ||
        contentType.contains('excel') ||
        contentType.contains('powerpoint') ||
        contentType.contains('text');
  }
}
