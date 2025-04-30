class ApiConstants {
  // Android emulator uses 10.0.2.2 to access host machine's localhost
  // iOS simulator uses localhost
  // For real device testing, use the actual machine's IP address

  // Network detection and configuration
  static String get baseUrl {
    // Platform-specific base URLs
    const emulatorUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
    const simulatorUrl = 'http://localhost:3000/api/v1'; // iOS simulator
    const localNetworkUrl = 'http://192.168.1.X:3000/api/v1'; // Real device (change X to your PC's last IP octet)
    const testApiUrl = 'http://10.0.2.2:3000/api/v1'; // Default for testing

    // Use Android emulator address by default for now
    return emulatorUrl;
  }

  // User endpoints
  static const String user = '/users';
  static const String userFavorites = '/users/favorites';
  static const String userCart = '/users/cart';
  static const String userMe = '/users/me';
  static const String userUpdatePassword = '/users/update-password';
  static const String userCards = '/users/cards';
  
  // User profile endpoints
  static String getUserProfileUrl() => '$baseUrl$userMe'; // GET ve PATCH için
  static String getUserUpdatePasswordUrl() => '$baseUrl$userUpdatePassword'; // PATCH için
  
  // User cards endpoints
  static String getUserCardsUrl() => '$baseUrl$userCards'; // GET ve POST için
  static String getUserCardUrl(String cardId) => '$baseUrl$userCards/$cardId'; // PATCH ve DELETE için
  
  // User favorites endpoints - RESTful yapı
  static String getUserFavoritesUrl() => '$baseUrl$userFavorites'; // GET için
  static String getUserFavoriteUrl(String productId) => '$baseUrl$userFavorites/$productId'; // POST/DELETE için
  
  // User cart endpoints - RESTful yapı
  static String getUserCartUrl() => '$baseUrl$userCart'; // GET için
  static String getUserCartItemUrl(String productId) => '$baseUrl$userCart/$productId'; // POST/DELETE için

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String signup = '/auth/signup';
  static const String verifyEmail = '/auth/verify-email';
  static const String deleteUser = '/auth/delete-user';

  // Product endpoints
  static const String products = '/products';
  static const String sellerProducts = '/products/seller';
  static const String myProducts = '/products/my/products';
  static const String productsByCategory = '/products/category';
  static const String productReviews = '/products'; // Base URL for reviews endpoint

  // Full product URLs
  static String getProductsUrl() => '$baseUrl$products';
  static String getProductUrl(String id) => '$baseUrl$products/$id';
  static String getProductReviewsUrl(String productId) => '$baseUrl$products/$productId/reviews';
  
  // Seller endpoints
  static const String sellers = '/sellers';
  static const String registerAsSeller = '/sellers/register';
  static const String sellerProfile = '/sellers/profile';
  static const String verifyDocuments = '/sellers/verify/documents';
  static const String verificationStatus = '/sellers/verify/status';
}
