class ApiConstants {
  // Android emulator uses 10.0.2.2 to access host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/signup';
  static const String verifyEmail = '$baseUrl/auth/verify-email';
  static const String deleteUser = '$baseUrl/auth/deleteuser';

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
