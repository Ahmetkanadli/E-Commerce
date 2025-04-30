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
    this.statusCode = 200,
    this.token,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJson) {
    // Extract status safely
    bool isSuccess = false;
    if (json.containsKey('status')) {
      isSuccess = json['status'] == 'success';
    } else if (json.containsKey('success')) {
      isSuccess = json['success'] == true;
    }

    // Extract message safely
    String msg = '';
    if (json.containsKey('message') && json['message'] != null) {
      msg = json['message'].toString();
    }

    // Extract token safely
    String? tokenValue;
    if (json.containsKey('token') && json['token'] != null) {
      tokenValue = json['token'].toString();
    }

    // Safely parse data
    T? parsedData;
    if (fromJson != null && json.containsKey('data')) {
      try {
        if (json['data'] is Map<String, dynamic>) {
          parsedData = fromJson(json['data']);
        } else if (json['data'] is Map) {
          // Try to convert to Map<String, dynamic> if it's just a Map
          parsedData = fromJson(Map<String, dynamic>.from(json['data'] as Map));
        }
      } catch (e) {
        print('Error parsing data in ApiResponse: $e');
        // In case of parsing error, leave data as null
      }
    } else if (fromJson != null) {
      // If no "data" field exists, try to parse the entire json
      try {
        parsedData = fromJson(json);
      } catch (e) {
        print('Error parsing full json in ApiResponse: $e');
      }
    }

    return ApiResponse(
      success: isSuccess,
      message: msg,
      data: parsedData,
      token: tokenValue,
      statusCode: json['statusCode'] is int ? json['statusCode'] : 200,
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
