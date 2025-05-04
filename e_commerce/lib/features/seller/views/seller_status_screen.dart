import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/cache/cache_manager.dart';
import 'package:e_commerce/features/seller/views/seller_registration_screen.dart';

class SellerStatusScreen extends StatefulWidget {
  const SellerStatusScreen({super.key});

  @override
  State<SellerStatusScreen> createState() => _SellerStatusScreenState();
}

class _SellerStatusScreenState extends State<SellerStatusScreen> {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  String _verificationStatus = '';
  bool _isVerified = false;
  bool _hasSellerAccount = false;

  @override
  void initState() {
    super.initState();
    _checkSellerStatus();
  }

  Future<void> _checkSellerStatus() async {
    try {
      final token = await CacheManager.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Oturum bilgileriniz bulunamadı. Lütfen tekrar giriş yapın.';
        });
        return;
      }

      final dio = Dio();
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.verificationStatus}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _hasSellerAccount = true;
          _verificationStatus = response.data['data']['verificationStatus'] ?? 'unknown';
          _isVerified = response.data['data']['isVerified'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Eğer hata 404 (satıcı bulunamadı) ise, satıcı hesabı yoktur
      if (e is DioException && e.response?.statusCode == 404) {
        setState(() {
          _hasSellerAccount = false;
          _isLoading = false;
        });
      } 
      // Eğer hata başka bir şey ise (örn. 401 - yetki hatası)
      else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildStatusCard() {
    late Color statusColor;
    late String statusText;
    late IconData statusIcon;

    switch (_verificationStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'İnceleme Bekliyor';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Onaylandı';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Reddedildi';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Bilinmiyor';
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 3,
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'Başvuru Durumu: $statusText',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              _getStatusDescription(),
              style: GoogleFonts.nunitoSans(
                fontSize: 16.sp,
              ),
            ),
            if (_verificationStatus == 'approved') ...[
              SizedBox(height: 16.h),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Burası, satıcı paneline yönlendirme eklenecek
                  },
                  icon: Icon(Icons.store, color: Colors.white),
                  label: Text('Satıcı Panelinize Gidin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                ),
              ),
            ],
            if (_verificationStatus == 'rejected') ...[
              SizedBox(height: 16.h),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerRegistrationScreen(),
                      ),
                    ).then((_) => _checkSellerStatus());
                  },
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text('Yeniden Başvur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusDescription() {
    switch (_verificationStatus) {
      case 'pending':
        return 'Satıcı başvurunuz ekibimiz tarafından inceleniyor. Bu işlem genellikle 1-3 iş günü içerisinde tamamlanır.';
      case 'approved':
        return 'Tebrikler! Satıcı başvurunuz onaylanmış ve hesabınız aktifleştirilmiştir. Artık ürün yükleyebilir ve satış yapabilirsiniz.';
      case 'rejected':
        return 'Üzgünüz, başvurunuz onaylanmadı. Verilen bilgileri kontrol edip tekrar başvuru yapabilirsiniz.';
      default:
        return 'Başvuru durumunuz hakkında bilgi bulunamadı.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Satıcı Durumu'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48.sp),
                      SizedBox(height: 16.h),
                      Text(
                        'Bir hata oluştu',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunitoSans(fontSize: 14.sp),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: _checkSellerStatus,
                        child: Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _hasSellerAccount
                  ? _buildStatusCard()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_outlined, color: Colors.blue, size: 64.sp),
                          SizedBox(height: 16.h),
                          Text(
                            'Henüz bir satıcı hesabınız yok',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Hemen başvurun ve ürünlerinizi satmaya başlayın!',
                            style: GoogleFonts.nunitoSans(fontSize: 14.sp),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SellerRegistrationScreen(),
                                ),
                              ).then((_) => _checkSellerStatus());
                            },
                            icon: Icon(Icons.add_business, color: Colors.white),
                            label: Text('Satıcı Olmak İçin Başvur'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004CFF),
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
} 