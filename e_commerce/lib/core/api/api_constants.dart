class ApiConstants {
  // Android emulator uses 10.0.2.2 to access host machine's localhost
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String deleteUser = '/auth/delete-user';

  // Product endpoints
  static const String products = '$baseUrl/products';
  static const String sellerProducts = '$baseUrl/products/seller';
  static const String myProducts = '$baseUrl/products/my/products';

  // Seller endpoints
  static const String sellers = '$baseUrl/sellers';
  static const String registerAsSeller = '$baseUrl/sellers/register';
  static const String sellerProfile = '$baseUrl/sellers/profile';
  static const String verifyDocuments = '$baseUrl/sellers/verify/documents';
  static const String verificationStatus = '$baseUrl/sellers/verify/status';
}
