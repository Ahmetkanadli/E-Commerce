import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/services/auth_service.dart';
import 'package:e_commerce/features/products/models/product_model.dart';
import 'package:e_commerce/features/products/views/product_detail_screen.dart';
import 'dart:developer' as developer;

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class CartItem {
  final ProductModel product;
  final String color;
  final String size;
  int quantity;
  final String id; // Sepet öğesi ID'si

  CartItem({
    required this.product,
    required this.color,
    required this.size,
    required this.quantity,
    required this.id,
  });

  double get totalPrice => product.price * quantity;

  static CartItem fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> productData = {};
    
    // Ürün verisinin farklı şekillerde gelebileceğini kontrol et
    if (json.containsKey('product')) {
      if (json['product'] is Map) {
        productData = Map<String, dynamic>.from(json['product']);
      } else if (json['product'] is String) {
        // Eğer product sadece bir ID string'i ise
        productData = {
          '_id': json['product'],
          'name': 'Ürün Adı',
          'price': 0.0,
          'images': <String>[],
          'seller': '',
          'description': '',
          'category': '',
          'stock': 0,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        };
        print('⚠️ Ürün verisi eksik, sadece ID mevcut: ${json['product']}');
      }
    } else {
      // Ürün verisi yoksa
      print('⚠️ Sepet öğesinde ürün verisi bulunamadı');
      productData = {
        '_id': json['_id'] ?? '',
        'name': 'Bilinmeyen Ürün',
        'price': 0.0,
        'images': <String>[],
      };
    }
    
    return CartItem(
      product: ProductModel.fromJson(productData),
      color: json['color'] ?? 'Standart',
      size: json['size'] ?? 'M',
      quantity: json['quantity'] ?? 1,
      id: json['_id'] ?? '',
    );
  }
}

class _CartScreenState extends State<CartScreen> {
  bool isLoading = true;
  List<CartItem> cartItems = [];
  String? authToken;
  bool isUpdatingCart = false;
  
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
        _loadCart();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadCart() async {
    if (authToken == null) {
      print('Sepeti yükleyemiyorum: Kullanıcı giriş yapmamış');
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      cartItems = [];
    });
    
    try {
      final dio = Dio();
      final url = ApiConstants.getUserCartUrl();
      print('🛒 Sepeti yüklemek için URL: $url');
      
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
      
      print('🛒 Sepet yanıtı: Durum Kodu: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        print('🛒 Yanıt: ${response.data}');
        
        final data = response.data;
        List? cartItems;
        
        // API yanıt yapısını analiz et
        if (data is Map) {
          // Doğrudan yanıt yapısını kontrol et
          if (data['status'] == 'success' && data['data'] is Map) {
            final cartData = data['data'];
            
            // Cart objesi kontrolü
            if (cartData['cart'] is Map && cartData['cart']['items'] is List) {
              cartItems = cartData['cart']['items'] as List;
              print('🛒 Doğru sepet yapısı bulundu: data.cart.items');
            }
            // Items listesini direkt kontrol et
            else if (cartData['items'] is List) {
              cartItems = cartData['items'] as List;
              print('🛒 Doğru sepet yapısı bulundu: data.items');
            }
            // Alternatif tüm yapılar
            else if (cartData['cart'] is List) {
              cartItems = cartData['cart'] as List;
              print('🛒 Alternatif sepet yapısı bulundu: data.cart (liste)');
            }
          }
          // Diğer muhtemel yapılar
          else if (data['cart'] is Map && data['cart']['items'] is List) {
            cartItems = data['cart']['items'] as List;
            print('🛒 Alternatif sepet yapısı bulundu: cart.items');
          }
          else if (data['cart'] is List) {
            cartItems = data['cart'] as List;
            print('🛒 Alternatif sepet yapısı bulundu: cart (liste)');
          }
          else if (data['items'] is List) {
            cartItems = data['items'] as List;
            print('🛒 Alternatif sepet yapısı bulundu: items (liste)');
          }
        }
        
        if (cartItems != null && cartItems.isNotEmpty) {
          print('🛒 Bulunan sepet öğeleri: ${cartItems.length}');
          
          List<CartItem> items = [];
          
          for (var item in cartItems) {
            if (item == null) continue;
            
            try {
              if (item is Map) {
                // Sepet öğesini dönüştür
                final cartItem = CartItem.fromJson(Map<String, dynamic>.from(item));
                items.add(cartItem);
              }
            } catch (e) {
              print('❌ Sepet öğesi dönüştürme hatası: $e');
              print('Hataya neden olan veri: $item');
            }
          }
          
          setState(() {
            this.cartItems = items;
            isLoading = false;
          });
          
          print('✅ ${items.length} ürün sepete yüklendi');
        } else {
          print('⚠️ Sepet boş veya bulunamadı. İşlenen veri: $data');
          setState(() {
            cartItems = [];
            isLoading = false;
          });
        }
      } else {
        print('⚠️ Sepet yanıtı geçersiz. Durum kodu: ${response.statusCode}');
        setState(() {
          cartItems = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Sepeti yüklerken hata oluştu: $e');
      setState(() {
        cartItems = [];
        isLoading = false;
      });
    }
  }
  
  Future<void> _updateCartItem(CartItem item, int newQuantity) async {
    if (authToken == null) {
      _showMessage('Sepeti güncellemek için giriş yapmalısınız', isError: true);
      return;
    }
    
    if (newQuantity <= 0) {
      // Ürün çıkarmak istiyorsa onay iste
      _confirmRemoveFromCart(item);
      return;
    }
    
    setState(() {
      isUpdatingCart = true;
    });
    
    try {
      final dio = Dio();
      
      // Sepet öğesi ID'si yerine ürün ID'si kullan
      // URL yapısı: /users/cart/:productId
      final String cartUrl = ApiConstants.getUserCartItemUrl(item.product.id);
      print('🛒 Sepet güncelleme URL: $cartUrl');
      print('🛒 Güncellenen ürün ID: ${item.product.id}, Sepet öğesi ID: ${item.id}');
      
      // Güncellenecek detayları hazırla
      final Map<String, dynamic> cartData = {
        'color': item.color,
        'size': item.size,
        'quantity': newQuantity,
      };
      
      print('🛒 Sepet güncelleme veri: $cartData');
      
      // PATCH isteği gönder (PUT yerine)
      final response = await dio.patch(
        cartUrl,
        data: cartData,
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
      
      print('🛒 Sepet güncelleme yanıtı: Durum Kodu: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        setState(() {
          item.quantity = newQuantity;
        });
        
        _showMessage('Sepet güncellendi');
      } else {
        print('⚠️ Sepet güncelleme işlemi başarısız. Durum kodu: ${response.statusCode}');
        _showMessage('İşlem sırasında bir hata oluştu', isError: true);
        _loadCart(); // Güncel sepet durumu için yeniden yükle
      }
    } catch (e) {
      print('❌ Sepet güncellemesi sırasında hata oluştu: $e');
      print('❌ Ürün ID: ${item.product.id}, Sepet öğesi ID: ${item.id}');
      if (e is DioException) {
        print('❌ Dio hatası: ${e.response?.statusCode} - ${e.response?.data}');
        print('❌ URL: ${e.requestOptions.uri}');
        print('❌ Metot: ${e.requestOptions.method}');
      }
      _showMessage('İşlem sırasında bir hata oluştu', isError: true);
      _loadCart(); // Güncel sepet durumu için yeniden yükle
    } finally {
      setState(() {
        isUpdatingCart = false;
      });
    }
  }
  
  // Ürünü sepetten çıkarma işlemini onaylama
  Future<void> _confirmRemoveFromCart(CartItem item) async {
    // iOS tarzında onay dialogu göster
    final bool confirm = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Ürünü Çıkar'),
        content: Text('Bu ürünü sepetten çıkarmak istiyor musunuz?'),
        actions: [
          CupertinoDialogAction(
            child: Text('İptal'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: Text('Çıkar'),
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      _removeFromCart(item.id);
    }
  }
  
  Future<void> _removeFromCart(String cartItemId) async {
    if (authToken == null) {
      _showMessage('Sepetten çıkarmak için giriş yapmalısınız', isError: true);
      return;
    }
    
    // Önce sepet öğesini bul
    final cartItem = cartItems.firstWhere(
      (item) => item.id == cartItemId,
      orElse: () => throw Exception('Sepet öğesi bulunamadı'),
    );
    
    // Eğer ürün miktarı 1 ise, çıkarmadan önce onay iste
    if (cartItem.quantity == 1) {
      final bool confirm = await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Ürünü Çıkar'),
          content: Text('Bu ürünü sepetten çıkarmak istiyor musunuz?'),
          actions: [
            CupertinoDialogAction(
              child: Text('İptal'),
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              child: Text('Çıkar'),
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) {
        return; // Kullanıcı onaylamadıysa işlemi iptal et
      }
    }
    
    setState(() {
      isUpdatingCart = true;
    });
    
    try {
      final dio = Dio();
      
      // Ürün ID kullanarak endpoint oluştur (/users/cart/:productId)
      final String cartUrl = ApiConstants.getUserCartItemUrl(cartItem.product.id);
      print('🛒 Sepetten çıkarma URL: $cartUrl');
      print('🛒 Çıkarılan ürün ID: ${cartItem.product.id}, Sepet öğesi ID: ${cartItem.id}');
      
      // DELETE isteği gönder
      final response = await dio.delete(
        cartUrl,
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
      
      print('🛒 Sepetten çıkarma yanıtı: Durum Kodu: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Sepet öğesini listeden kaldır
        setState(() {
          cartItems.removeWhere((item) => item.id == cartItemId);
        });
        
        _showMessage('Ürün sepetten çıkarıldı');
      } else {
        print('⚠️ Sepetten çıkarma işlemi başarısız. Durum kodu: ${response.statusCode}');
        _showMessage('İşlem sırasında bir hata oluştu', isError: true);
        _loadCart(); // Güncel sepet durumu için yeniden yükle
      }
    } catch (e) {
      print('❌ Sepetten çıkarma sırasında hata oluştu: $e');
      if (e is DioException) {
        print('❌ Dio hatası: ${e.response?.statusCode} - ${e.response?.data}');
        print('❌ URL: ${e.requestOptions.uri}');
      }
      _showMessage('İşlem sırasında bir hata oluştu', isError: true);
      _loadCart(); // Güncel sepet durumu için yeniden yükle
    } finally {
      setState(() {
        isUpdatingCart = false;
      });
    }
  }
  
  Future<void> _clearCart() async {
    if (authToken == null) {
      _showMessage('Sepeti temizlemek için giriş yapmalısınız', isError: true);
      return;
    }
    
    // Onay isteyelim
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sepeti Temizle'),
        content: Text('Sepetteki tüm ürünleri çıkarmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Temizle'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      isUpdatingCart = true;
    });
    
    try {
      final dio = Dio();
      
      // Tüm sepeti temizlemek için URL
      final String cartUrl = ApiConstants.getUserCartUrl();
      print('🛒 Sepeti temizleme URL: $cartUrl');
      
      // DELETE isteği gönder
      final response = await dio.delete(
        cartUrl,
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
      
      print('🛒 Sepeti temizleme yanıtı: Durum Kodu: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Sepeti temizle
        setState(() {
          cartItems = [];
        });
        
        _showMessage('Sepet temizlendi');
      } else {
        print('⚠️ Sepeti temizleme işlemi başarısız. Durum kodu: ${response.statusCode}');
        _showMessage('İşlem sırasında bir hata oluştu', isError: true);
      }
    } catch (e) {
      print('❌ Sepeti temizleme sırasında hata oluştu: $e');
      _showMessage('İşlem sırasında bir hata oluştu', isError: true);
    } finally {
      setState(() {
        isUpdatingCart = false;
      });
    }
  }
  
  double get _totalPrice {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
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
        title: const Text('Sepetim'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: _clearCart,
              tooltip: 'Sepeti Temizle',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCart,
            tooltip: 'Yenile',
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
                    'Sepeti görüntülemek için giriş yapmalısınız',
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
          : cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Sepetiniz boş',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Ürünleri sepetinize ekleyebilirsiniz',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Sepet öğeleri
                  ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 80.r), // Alt kısımda ödeme butonuna yer bırak
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartItems[index];
                      return _buildCartItemCard(cartItem);
                    },
                  ),
                  
                  // Sipariş özeti ve ödeme butonu
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildOrderSummary(),
                  ),
                ],
              ),
    );
  }
  
  Widget _buildCartItemCard(CartItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(8.r),
        child: Column(
          children: [
            Row(
              children: [
                // Ürün resmi
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: item.product),
                      ),
                    ).then((_) => _loadCart()); // Sepet ekranına dönüldüğünde sepeti yenile
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      width: 80.w,
                      height: 80.h,
                      child: item.product.images.isNotEmpty
                        ? Image.network(
                            item.product.images.first,
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
                ),
                SizedBox(width: 12.w),
                // Ürün bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '₺${item.product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          _buildInfoTag(item.color),
                          SizedBox(width: 8.w),
                          _buildInfoTag(item.size),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sepetten çıkar butonu
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => _removeFromCart(item.id),
                ),
              ],
            ),
            
            // Miktar ayarlama kısmı
            Padding(
              padding: EdgeInsets.only(top: 8.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () => _updateCartItem(item, item.quantity - 1),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => _updateCartItem(item, item.quantity + 1),
                      ),
                    ],
                  ),
                  Text(
                    'Toplam: ₺${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[800],
        ),
      ),
    );
  }
  
  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18.r),
        onPressed: isUpdatingCart ? null : onPressed,
        padding: EdgeInsets.all(4.r),
        constraints: BoxConstraints(
          minWidth: 32.w,
          minHeight: 32.h,
        ),
      ),
    );
  }
  
  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Toplam:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₺${_totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton(
                onPressed: isUpdatingCart || cartItems.isEmpty ? null : () {
                  // Ödeme sayfasına yönlendir
                  _showMessage('Ödeme sayfasına yönlendiriliyorsunuz...');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Satın Al',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 