class Constants {
  // API URLs
  static const String baseUrl = 'https://657fc7106ae0629a3f53a003.mockapi.io';

  // Auth endpoints
  static const String registerEndpoint = '/users';
  static const String loginEndpoint = '/users';
  static const String userEndpoint = '/users';

  // Manga endpoints
  static const String mangasEndpoint = '/mangas';
  static const String chaptersEndpoint = '/chapters';

  // Local storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String usersKey = 'all_users';
  static const String readingHistoryKey = 'reading_history';
}