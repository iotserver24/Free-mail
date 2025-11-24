class AppConstants {
  // App Info
  static const String appName = 'Freemail';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keyBackendUrl = 'backend_url';
  static const String keySessionCookie = 'session_cookie';
  static const String keyEmail = 'email';
  static const String keyPassword = 'password';
  
  // API Endpoints
  static const String apiAuth = '/api/auth';
  static const String apiMessages = '/api/messages';
  static const String apiDomains = '/api/domains';
  static const String apiInboxes = '/api/inboxes';
  static const String apiEmails = '/api/emails';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const int maxEmailPreviewLength = 100;
  
  // Email Folders
  static const String folderInbox = 'inbox';
  static const String folderSent = 'sent';
  static const String folderDrafts = 'drafts';
  static const String folderTrash = 'trash';
  
  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;
}
