class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;
  final String? token;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
    this.token,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJson) {
    return ApiResponse(
      success: json['status'] == 'success',
      message: json['message'] ?? '',
      data: fromJson != null && json['data'] != null
          ? fromJson(json['data'])
          : null,
      token: json['token'],
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String message, {int statusCode = 400}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
