import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/services/auth_service.dart';
import 'package:e_commerce/features/products/models/product_model.dart';
import 'package:e_commerce/features/products/views/product_detail_screen.dart';
import 'dart:developer' as developer;

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool isLoading = true;
  List<ProductModel> favoriteProducts = [];
  String? authToken;
  
  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }
  
  Future<void> _loadAuthToken() async {
    final AuthService authService = AuthService();
    final token = await authService.getToken();
    
    if (mounted) {
      setState(() {
        authToken = token;
      });
      
      print('Auth token loaded: ${authToken != null ? 'Available' : 'Not available'}');
      
      if (authToken != null) {
        _loadFavorites();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadFavorites() async {
    if (authToken == null) {
      print('Favorileri yükleyemiyorum: Kullanıcı giriş yapmamış');
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      favoriteProducts = [];
    });
    
    try {
      final dio = Dio();
      final url = ApiConstants.getUserFavoritesUrl();
      print('🔍 Favorileri yüklemek için URL: $url');
      
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      print('🔍 Favoriler yanıtı: Durum Kodu: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        print('🔍 Yanıt: ${response.data}');
        
        final data = response.data;
        List? favoritesData;
        
        // API yanıt yapısını analiz et
        if (data is Map) {
          // Standart API yanıtı: { data: [...] }
          if (data.containsKey('data')) {
            if (data['data'] is List) {
              favoritesData = data['data'] as List;
            } else if (data['data'] is Map && data['data'].containsKey('favorites')) {
              // Alternatif API yanıtı: { data: { favorites: [...] } }
              favoritesData = data['data']['favorites'] as List?;
            }
          // Doğrudan favorites: [...] yapısı
          } else if (data.containsKey('favorites')) {
            favoritesData = data['favorites'] as List?;
          }
        } else if (data is List) {
          // Doğrudan liste yanıtı: [...]
          favoritesData = data;
        }
        
        if (favoritesData != null && favoritesData.isNotEmpty) {
          print('🔍 Bulunan favoriler: ${favoritesData.length}');
          
          List<ProductModel> products = [];
          
          for (var item in favoritesData) {
            if (item == null) continue;
            
            try {
              // Doğrudan ürün nesnesi olabilir
              if (item is Map && (item.containsKey('_id') || item.containsKey('name'))) {
                products.add(ProductModel.fromJson(Map<String, dynamic>.from(item)));
                continue;
              }
              
              // Product referansı içerebilir
              if (item is Map && item.containsKey('product')) {
                var product = item['product'];
                if (product is Map) {
                  products.add(ProductModel.fromJson(Map<String, dynamic>.from(product)));
                }
              }
            } catch (e) {
              print('❌ Ürün dönüştürme hatası: $e');
            }
          }
          
          setState(() {
            favoriteProducts = products;
            isLoading = false;
          });
          
          print('✅ ${products.length} ürün favori listesine yüklendi');
        } else {
          print('⚠️ Favori listesi boş veya bulunamadı');
          setState(() {
            favoriteProducts = [];
            isLoading = false;
          });
        }
      } else {
        print('⚠️ Favoriler yanıtı geçersiz. Durum kodu: ${response.statusCode}');
        setState(() {
          favoriteProducts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Favorileri yüklerken hata oluştu: $e');
      setState(() {
        favoriteProducts = [];
        isLoading = false;
      });
    }
  }
  
  Future<void> _removeFromFavorites(String productId) async {
    if (authToken == null) {
      _showMessage('Favorilerden çıkarmak için giriş yapmalısınız', isError: true);
      return;
    }
    
    try {
      final dio = Dio();
      
      // Favorilerden çıkarmak için URL'yi oluştur
      final String favoriteUrl = ApiConstants.getUserFavoriteUrl(productId);
      print('🔍 Favorilerden çıkarma URL: $favoriteUrl');
      
      // DELETE isteği gönder
      final response = await dio.delete(
        favoriteUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      print('🔍 Favorilerden çıkarma yanıtı: Durum Kodu: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Listeden kaldır
        setState(() {
          favoriteProducts.removeWhere((product) => product.id == productId);
        });
        
        _showMessage('Ürün favorilerden kaldırıldı');
      } else {
        print('⚠️ Favorilerden çıkarma işlemi başarısız. Durum kodu: ${response.statusCode}');
        _showMessage('İşlem sırasında bir hata oluştu', isError: true);
      }
    } catch (e) {
      print('❌ Favorilerden çıkarma sırasında hata oluştu: $e');
      _showMessage('İşlem sırasında bir hata oluştu', isError: true);
    }
  }
  
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8.r),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstek Listem'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : authToken == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Favorileri görüntülemek için giriş yapmalısınız',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      // Login sayfasına yönlendir
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Giriş Yap'),
                  ),
                ],
              ),
            )
          : favoriteProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Favori listeniz boş',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Beğendiğiniz ürünleri favorilere ekleyebilirsiniz',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = favoriteProducts[index];
                  return _buildProductCard(product);
                },
              ),
    );
  }
  
  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          ).then((_) => _loadFavorites()); // Favori ekranına dönüldüğünde favorileri yenile
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Row(
            children: [
              // Ürün resmi
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                ),
              ),
              SizedBox(width: 12.w),
              // Ürün bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '₺${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Stok: ${product.stock}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: product.stock > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Favorilerden kaldır butonu
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey),
                onPressed: () => _removeFromFavorites(product.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 