import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:e_commerce/features/products/models/product_model.dart';
import 'package:e_commerce/features/products/models/review_model.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/repository/product_repository.dart';
import 'package:e_commerce/core/services/auth_service.dart';
import 'package:e_commerce/core/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'dart:math';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int selectedColorIndex = 0;
  int selectedSizeIndex = 0;
  int currentImageIndex = 0;
  bool isLoadingReviews = true;
  List<ReviewModel> reviews = [];
  double averageRating = 0.0;
  bool isFavorite = false;
  bool isLoadingFavorite = false;
  bool isAddingToCart = false;
  String? authToken;
  
  // Mock data for the UI
  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.white,
  ];
  
  final List<String> availableSizes = ['XS', 'S', 'M', 'L', 'XL'];
  
  @override
  void initState() {
    super.initState();
    print('ProductDetailScreen initialized with product ID: ${widget.product.id}');
    _loadReviews();
    _loadAuthToken();
  }
  
  bool _isFirstLoad = true;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isFirstLoad) {
      // Sayfaya geri dönüldüğünde favori durumunu yeniden kontrol et
      print('🔄 Sayfaya geri dönüldüğünde favori durumu kontrol ediliyor');
      if (authToken != null) {
        _checkFavoriteStatus();
      }
    } else {
      _isFirstLoad = false;
    }
  }
  
  @override
  void didUpdateWidget(ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Eğer farklı bir ürüne geçildiyse, favori durumunu yenile
    if (oldWidget.product.id != widget.product.id) {
      print('🔄 Farklı bir ürüne geçildi, favori durumu kontrol ediliyor');
      if (authToken != null) {
        _checkFavoriteStatus();
      }
    }
  }
  
  Future<void> _loadAuthToken() async {
    // AuthService kullanarak token'ı al
    final AuthService authService = AuthService();
    final token = await authService.getToken();
    
    if (mounted) {
      setState(() {
        authToken = token;
      });
      
      print('Auth token loaded: ${authToken != null ? 'Available' : 'Not available'}');
      
      // Token yüklendikten sonra favori durumunu kontrol et
      if (authToken != null) {
        _checkFavoriteStatus();
      }
    }
  }
  
  // Yerel favori durumunu kontrol eden metot
  Future<bool> _checkLocalFavoriteStatus(String productId) async {
    try {
      final StorageService storageService = StorageService();
      final String key = 'favorite_$productId';
      final String? value = await storageService.getData(key);
      
      print('🔍 Yerel favori durumu kontrolü: $key = $value');
      return value == 'true';
    } catch (e) {
      print('❌ Yerel favori durumu kontrol edilirken hata: $e');
      return false;
    }
  }
  
  // Yerel favori durumunu kaydeden metot
  Future<void> _saveLocalFavoriteStatus(String productId, bool isFavorite) async {
    try {
      final StorageService storageService = StorageService();
      final String key = 'favorite_$productId';
      final String value = isFavorite.toString();
      
      await storageService.saveData(key, value);
      print('✅ Yerel favori durumu kaydedildi: $key = $value');
    } catch (e) {
      print('❌ Yerel favori durumu kaydedilirken hata: $e');
    }
  }
  
  Future<void> _checkFavoriteStatus() async {
    if (authToken == null) {
      print('Favori durumu kontrol edilemiyor: Kullanıcı giriş yapmamış');
      return;
    }
    
    setState(() {
      isLoadingFavorite = true;
    });
    
    final String productId = widget.product.id;
    
    // Önce yerel durumu kontrol et ve hızlıca göster
    final bool localFavoriteStatus = await _checkLocalFavoriteStatus(productId);
    if (localFavoriteStatus) {
      print('🔍 Yerel kaydedilmiş favori durumu: Favorilerde ✅');
      setState(() {
        isFavorite = true;
      });
    }
    
    try {
      print('🔍 _checkFavoriteStatus - Ürün ID: $productId');
      
      final dio = Dio();
      final url = ApiConstants.getUserFavoritesUrl();
      print('🔍 Favorileri kontrol etmek için URL: $url');
      
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
      
      print('🔍 Favori durumu yanıtı: Durum Kodu: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        print('🔍 Yanıt veri türü: ${response.data.runtimeType}');
        print('🔍 Yanıt: ${response.data}');
        
        final data = response.data;
        List? favorites;
        
        // API yanıt yapısını analiz et
        if (data is Map) {
          // Standart API yanıtı: { data: [...] }
          if (data.containsKey('data')) {
            if (data['data'] is List) {
              favorites = data['data'] as List;
            } else if (data['data'] is Map && data['data'].containsKey('favorites')) {
              // Alternatif API yanıtı: { data: { favorites: [...] } }
              favorites = data['data']['favorites'] as List?;
            }
          // Doğrudan favorites: [...] yapısı
          } else if (data.containsKey('favorites')) {
            favorites = data['favorites'] as List?;
          }
        } else if (data is List) {
          // Doğrudan liste yanıtı: [...]
          favorites = data;
        }
        
        if (favorites != null && favorites.isNotEmpty) {
          print('🔍 Bulunan favoriler: ${favorites.length}');
          
          if (favorites.isNotEmpty) {
            print('🔍 İlk favori örneği:');
            print(favorites[0]);
          }
          
          // Ürün ID'lerini kontrol et
          bool isProductFavorite = false;
          
          for (var fav in favorites) {
            if (fav == null) continue;
            
            // ID kontrolü için çeşitli yapıları dene
            if (fav is String && fav == productId) {
              isProductFavorite = true;
              print('🎯 String ID eşleşmesi: $fav == $productId');
              break;
            } 
            
            if (fav is Map) {
              // Direkt _id alanı kontrol et
              if (fav.containsKey('_id')) {
                String favId = fav['_id']?.toString() ?? '';
                if (favId == productId) {
                  isProductFavorite = true;
                  print('🎯 Eşleşme bulundu - _id: $favId == $productId');
                  break;
                }
              }
              
              // id alanını kontrol et
              if (fav.containsKey('id')) {
                String favId = fav['id']?.toString() ?? '';
                if (favId == productId) {
                  isProductFavorite = true;
                  print('🎯 Eşleşme bulundu - id: $favId == $productId');
                  break;
                }
              }
              
              // Alt product nesnesi kontrol et
              if (fav.containsKey('product')) {
                var product = fav['product'];
                // Product bir Map ise
                if (product is Map) {
                  // product._id kontrolü
                  if (product.containsKey('_id')) {
                    String prodId = product['_id']?.toString() ?? '';
                    if (prodId == productId) {
                      isProductFavorite = true;
                      print('🎯 Eşleşme bulundu - product._id: $prodId == $productId');
                      break;
                    }
                  }
                  
                  // product.id kontrolü
                  if (product.containsKey('id')) {
                    String prodId = product['id']?.toString() ?? '';
                    if (prodId == productId) {
                      isProductFavorite = true;
                      print('🎯 Eşleşme bulundu - product.id: $prodId == $productId');
                      break;
                    }
                  }
                } 
                // Product bir String ise
                else if (product is String) {
                  if (product == productId) {
                    isProductFavorite = true;
                    print('🎯 Eşleşme bulundu - product: $product == $productId');
                    break;
                  }
                }
              }
            }
          }
          
          // Yerel durumu API sonucuna göre güncelle
          await _saveLocalFavoriteStatus(productId, isProductFavorite);
          
          setState(() {
            isFavorite = isProductFavorite;
            isLoadingFavorite = false;
          });
          
          print('🔍 Favori durumu: ${isFavorite ? 'Favorilerde ✅' : 'Favorilerde değil ❌'}');
        } else {
          print('⚠️ Favori listesi boş veya bulunamadı');
          
          // API favorilerde olmadığını gösteriyorsa yerel durumu da güncelle
          await _saveLocalFavoriteStatus(productId, false);
          
          setState(() {
            isFavorite = false;
            isLoadingFavorite = false;
          });
        }
      } else {
        print('⚠️ Favori durumu yanıtı geçersiz. Durum kodu: ${response.statusCode}');
        setState(() {
          isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('❌ Favori durumu kontrol edilirken hata oluştu: $e');
      setState(() {
        isLoadingFavorite = false;
      });
    }
  }
  
  Future<void> _toggleFavorite() async {
    if (authToken == null) {
      showCustomSnackBar(
        context,
        'Favori eklemek için giriş yapmalısınız',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoadingFavorite = true;
    });

    try {
      final String productId = widget.product.id;
      print('🔍 _toggleFavorite - Ürün ID: $productId');
      
      final dio = Dio();
      
      // Favorilere eklemek veya çıkarmak için URL'yi oluştur
      final String favoriteUrl = ApiConstants.getUserFavoriteUrl(productId);
      print('🔍 Favori URL: $favoriteUrl');
      
      Response response;
      
      if (isFavorite) {
        // Favorilerden çıkarma - DELETE isteği
        print('🔍 Favorilerden çıkarma isteği gönderiliyor');
        response = await dio.delete(
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
      } else {
        // Favorilere ekleme - POST isteği
        print('🔍 Favorilere ekleme isteği gönderiliyor');
        response = await dio.post(
          favoriteUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            // 400 hatasını ele almak için validateStatus ekle
            validateStatus: (status) {
              return status != null && status < 500; // 400'ler dahil başarı sayılsın
            },
          ),
        );
      }

      print('🔍 Favori işlemi yanıtı: Durum Kodu: ${response.statusCode}');
      print('🔍 Yanıt: ${response.data}');

      // Başarılı yanıt VEYA "zaten favorilerde" hatası (400) durumunda
      if (response.statusCode == 200 || response.statusCode == 201 || 
          (response.statusCode == 400 && 
           response.data is Map && 
           response.data['message']?.toString().contains('favorilerinizde') == true)) {
        
        // 400 hatası ve "zaten favorilerde" mesajı, favoriye eklenmiş demektir
        final bool newFavoriteState = response.statusCode == 400 ? true : !isFavorite;
        
        // Yerel favori durumunu güncelle
        await _saveLocalFavoriteStatus(productId, newFavoriteState);
        
        setState(() {
          isFavorite = newFavoriteState;
          isLoadingFavorite = false;
        });
        
        showCustomSnackBar(
          context,
          isFavorite
              ? 'Ürün favorilere eklendi'
              : 'Ürün favorilerden çıkarıldı',
          isError: false,
        );
      } else {
        print('⚠️ Favori işlemi başarısız. Durum kodu: ${response.statusCode}');
        showCustomSnackBar(
          context,
          'Favori işlemi sırasında bir hata oluştu',
          isError: true,
        );
        setState(() {
          isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('❌ Favori işlemi sırasında hata oluştu: $e');
      if (e is DioException) {
        print('❌ Dio hatası: ${e.response?.statusCode} - ${e.response?.data}');
        
        // "Zaten favorilerde" hatası için özel durum kontrolü
        if (e.response?.statusCode == 400 && 
            e.response?.data is Map && 
            e.response?.data['message']?.toString().contains('favorilerinizde') == true) {
          
          // Yerel favori durumunu true olarak güncelle
          await _saveLocalFavoriteStatus(widget.product.id, true);
          
          setState(() {
            isFavorite = true;  // Zaten favorilerde olduğunu doğruladık
            isLoadingFavorite = false;
          });
          
          showCustomSnackBar(
            context,
            'Bu ürün zaten favorilerinizde',
            isError: false,
          );
          return;
        }
      }
      
      showCustomSnackBar(
        context,
        'Favori işlemi sırasında bir hata oluştu',
        isError: true,
      );
      setState(() {
        isLoadingFavorite = false;
      });
    }
  }
  
  Future<void> _loadReviews() async {
    setState(() {
      isLoadingReviews = true;
    });
    
    // Log the product ID for debugging
    print('🔍 Current product ID: ${widget.product.id}');
    
    // Explicitly use the test product ID for testing
    final String testProductId = '676986d171b208e3ffae1128'; 
    print('🔍 Using test product ID: $testProductId');
    
    // Use the correct IP for Android emulator (10.0.2.2 instead of localhost)
    // Create a direct URL to test with
    final directUrl = 'http://10.0.2.2:3000/api/v1/products/$testProductId/reviews';
    print('🔍 Direct URL: $directUrl');
    
    try {
      print('🔍 Fetching reviews for product ID: $testProductId');
      
      // Try direct URL approach
      final dio = Dio();
      print('🔍 Sending direct request to: $directUrl');
      
      // Add timeout for better error handling
      final response = await dio.get(
        directUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      print('🔍 Direct request response status: ${response.statusCode}');
      
      if (response.data != null) {
        print('🔍 Direct response data: ${response.data}');
        
        final json = response.data;
        List<ReviewModel> directReviews = [];
        
        try {
          if (json is Map<String, dynamic> && 
              json.containsKey('data') && 
              json['data'] is Map<String, dynamic> &&
              json['data'].containsKey('reviews')) {
            
            final reviewsData = json['data']['reviews'] as List;
            print('✅ Found ${reviewsData.length} reviews in direct response');
            
            for (var item in reviewsData) {
              if (item is Map<String, dynamic>) {
                try {
                  final review = ReviewModel.fromJson(item);
                  directReviews.add(review);
                  print('✅ Parsed review: ${review.text.substring(0, min(20, review.text.length))}...');
                } catch (e) {
                  print('❌ Error parsing review item: $e');
                }
              }
            }
            
            setState(() {
              reviews = directReviews;
              isLoadingReviews = false;
              
              // Calculate average rating
              if (reviews.isNotEmpty) {
                double total = reviews.fold(0.0, (sum, review) => sum + review.rating);
                averageRating = total / reviews.length;
                print('⭐ Average rating: $averageRating from ${reviews.length} reviews');
              } else {
                print('⚠️ No reviews found to calculate average rating');
              }
            });
            
            return; // Exit early if direct approach worked
          }
        } catch (e) {
          print('❌ Error processing direct response: $e');
        }
      }
      
      // Fall back to repository approach if direct approach failed
      final apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
      final productRepository = ProductRepository(apiClient);
      
      final result = await productRepository.getProductReviews(testProductId);
      
      print('🔍 Repository result received: ${result.toString()}');
      
      result.fold(
        (failure) {
          print('❌ Failed to load reviews: ${failure.message}');
          setState(() {
            isLoadingReviews = false;
          });
        },
        (reviewsList) {
          print('✅ Reviews loaded successfully: ${reviewsList.length} reviews found');
          if (reviewsList.isNotEmpty) {
            print('📝 First review: ${reviewsList.first.text}');
          }
          
          setState(() {
            reviews = reviewsList;
            isLoadingReviews = false;
            
            // Calculate average rating
            if (reviews.isNotEmpty) {
              double total = reviews.fold(0.0, (sum, review) => sum + review.rating);
              averageRating = total / reviews.length;
              print('⭐ Average rating: $averageRating');
            } else {
              print('⚠️ No reviews found to calculate average rating');
            }
          });
        },
      );
    } catch (e, stackTrace) {
      print('❌ Error loading reviews: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isLoadingReviews = false;
      });
    }
  }
  
  Future<void> _addToCart() async {
    if (authToken == null) {
      showCustomSnackBar(
        context,
        'Sepete eklemek için giriş yapmalısınız',
        isError: true,
      );
      return;
    }
    
    setState(() {
      isAddingToCart = true;
    });
    
    try {
      final String productId = widget.product.id;
      print('🛒 _addToCart - Ürün ID: $productId');
      
      final dio = Dio();
      
      // Sepete eklemek için URL'yi oluştur
      final String cartUrl = ApiConstants.getUserCartItemUrl(productId);
      print('🛒 Sepete ekle URL: $cartUrl');
      
      // Renk adını belirle (kırmızı, mavi, sarı, beyaz)
      String colorName = '';
      if (availableColors[selectedColorIndex] == Colors.red) {
        colorName = 'Kırmızı';
      } else if (availableColors[selectedColorIndex] == Colors.blue) {
        colorName = 'Mavi';
      } else if (availableColors[selectedColorIndex] == Colors.yellow) {
        colorName = 'Sarı';
      } else if (availableColors[selectedColorIndex] == Colors.white) {
        colorName = 'Beyaz';
      } else {
        colorName = 'Standart';
      }
      
      // Sepete eklenecek detayları hazırla
      final Map<String, dynamic> cartData = {
        'productId': productId,
        'color': colorName,
        'size': availableSizes[selectedSizeIndex],
        'quantity': 1, // Varsayılan miktar
      };
      
      print('🛒 Sepete eklenecek veri: $cartData');
      
      // POST isteği gönder
      final response = await dio.post(
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
          // 400 hatasını ele almak için validateStatus ekle
          validateStatus: (status) {
            return status != null && status < 500; // 400'ler dahil başarı sayılsın
          },
        ),
      );
      
      print('🛒 Sepete ekleme yanıtı: Durum Kodu: ${response.statusCode}');
      print('🛒 Yanıt: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        showCustomSnackBar(
          context,
          'Ürün sepete eklendi',
          isError: false,
        );
      } else if (response.statusCode == 400 &&
                response.data is Map &&
                response.data['message']?.toString().contains('sepetinizde') == true) {
        showCustomSnackBar(
          context,
          'Bu ürün zaten sepetinizde',
          isError: false,
        );
      } else {
        print('⚠️ Sepete ekleme işlemi başarısız. Durum kodu: ${response.statusCode}');
        showCustomSnackBar(
          context,
          'Sepete ekleme sırasında bir hata oluştu',
          isError: true,
        );
      }
    } catch (e) {
      print('❌ Sepete ekleme sırasında hata oluştu: $e');
      if (e is DioException) {
        print('❌ Dio hatası: ${e.response?.statusCode} - ${e.response?.data}');
        
        // "Zaten sepette" hatası için özel durum kontrolü
        if (e.response?.statusCode == 400 && 
            e.response?.data is Map && 
            e.response?.data['message']?.toString().contains('sepetinizde') == true) {
          
          showCustomSnackBar(
            context,
            'Bu ürün zaten sepetinizde',
            isError: false,
          );
          setState(() {
            isAddingToCart = false;
          });
          return;
        }
      }
      
      showCustomSnackBar(
        context,
        'Sepete ekleme sırasında bir hata oluştu',
        isError: true,
      );
    } finally {
      setState(() {
        isAddingToCart = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // App Bar with Product Image
              _buildAppBar(),
              
              // Product Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and dimensions
                      _buildPriceSection(),
                      
                      // Product name and description
                      _buildProductInfo(),
                      
                      // Color variations
                      _buildColorVariations(),
                      
                      // Specifications
                      _buildSpecifications(),
                      
                      // Size guide
                      _buildSizeGuide(),
                      
                      // Delivery options
                      _buildDeliveryOptions(),
                      
                      // Ratings and reviews
                      _buildRatingsAndReviews(),
                      
                      // Most popular section
                      _buildMostPopular(),
                      
                      // You might like section
                      _buildRecommendations(),
                      
                      // Extra space for bottom buttons
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActions(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 400.h,
      pinned: true,
      backgroundColor: Colors.yellow[100],
      flexibleSpace: FlexibleSpaceBar(
        background: PageView.builder(
          itemCount: widget.product.images.isEmpty ? 1 : widget.product.images.length,
          onPageChanged: (index) {
            setState(() {
              currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return widget.product.images.isEmpty
                ? Container(
                    color: Colors.yellow[100],
                    child: Center(
                      child: Icon(Icons.image_not_supported, size: 100.r, color: Colors.grey),
                    ),
                  )
                : Image.network(
                    widget.product.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.yellow[100],
                      child: Center(
                        child: Icon(Icons.image_not_supported, size: 100.r, color: Colors.grey),
                      ),
                    ),
                  );
          },
        ),
      ),
      actions: [
        IconButton(
          icon: isLoadingFavorite
              ? SizedBox(
                  width: 20.r, 
                  height: 20.r, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2.r,
                    color: Colors.red,
                  )
                )
              : Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.black,
                ),
          onPressed: isLoadingFavorite ? null : _toggleFavorite,
        ),
        IconButton(
          icon: Icon(Icons.share, color: Colors.black),
          onPressed: () {},
        ),
      ],
      leading: IconButton(
        icon: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: Colors.black),
          padding: EdgeInsets.all(4.r),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: widget.product.images.length > 1
          ? PreferredSize(
              preferredSize: Size.fromHeight(20.h),
              child: Container(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.product.images.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentImageIndex == index ? Colors.blue : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
  
  Widget _buildPriceSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '₺${widget.product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '120 × 10',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.product.description,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildColorVariations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seçenekler',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(
                availableColors.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColorIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: availableColors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColorIndex == index ? Colors.blue : Colors.grey.withOpacity(0.3),
                        width: selectedColorIndex == index ? 2 : 1,
                      ),
                    ),
                    child: selectedColorIndex == index
                        ? Icon(
                            Icons.check,
                            color: availableColors[index] == Colors.white ? Colors.black : Colors.white,
                            size: 20.r,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Text(
              '+15',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildSpecifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Özellikler',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecificationItem('Malzeme', 'Pamuk'),
                  _buildSpecificationItem('Stil', 'Spor XS'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecificationItem('Kalıp', 'Regular'),
                  _buildSpecificationItem('Malzeme', 'Pamuk'),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildSpecificationItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSizeGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Beden Rehberi',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.r,
              color: Colors.blue,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              availableSizes.length,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    selectedSizeIndex = index;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 10.w),
                  width: 40.w,
                  height: 40.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedSizeIndex == index ? Colors.blue : Colors.grey.withOpacity(0.3),
                      width: selectedSizeIndex == index ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4.r),
                    color: selectedSizeIndex == index ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: Text(
                    availableSizes[index],
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: selectedSizeIndex == index ? Colors.blue : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildDeliveryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teslimat',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildDeliveryOption('Standart', '3-5 gün', '₺39.99'),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDeliveryOption('Hızlı', '1-2 gün', '₺89.99'),
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildDeliveryOption(String type, String time, String price) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            price,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingsAndReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Değerlendirmeler & Yorumlar',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < averageRating.floor() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16.r,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (isLoadingReviews)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: CircularProgressIndicator(),
            ),
          )
        else if (reviews.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'Henüz yorum yok',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          Column(
            children: reviews.map((review) => _buildReviewItem(review)).toList(),
          ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildReviewItem(ReviewModel review) {
    final formattedDate = DateFormat('d MMM yyyy').format(review.createdAt);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey[200],
                backgroundImage: review.userAvatar != null ? NetworkImage(review.userAvatar!) : null,
                child: review.userAvatar == null 
                    ? Icon(Icons.person, color: Colors.grey[600], size: 16.r) 
                    : null,
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName ?? 'Anonim Kullanıcı',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 12.r,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            review.text.isNotEmpty ? review.text : "Yorum yapılmamış", 
            style: TextStyle(
              fontSize: 14.sp,
            ),
          ),
          
          // Display seller reply if exists
          if (review.sellerReply != null && review.sellerReply!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store, 
                        size: 16.r,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Satıcı Yanıtı',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Spacer(),
                      if (review.sellerReplyDate != null)
                        Text(
                          DateFormat('d MMM yyyy').format(review.sellerReplyDate!),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    review.sellerReply!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.thumb_up_outlined, size: 14.r),
                label: Text('Faydalı'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  textStyle: TextStyle(fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMostPopular() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'En Popüler',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              3,
              (index) => _buildPopularProductCard(index),
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildPopularProductCard(int index) {
    // Mock data for popular products
    final List<Map<String, dynamic>> popularProducts = [
      {
        'image': 'https://via.placeholder.com/150/pink',
        'name': 'Pembe Yaz Elbisesi',
        'price': 49.99,
      },
      {
        'image': 'https://via.placeholder.com/150/yellow',
        'name': 'Sarı T-Shirt',
        'price': 29.99,
      },
      {
        'image': 'https://via.placeholder.com/150/orange',
        'name': 'Turuncu Bluz',
        'price': 39.99,
      },
    ];
    
    final product = popularProducts[index];
    
    return Container(
      width: 120.w,
      margin: EdgeInsets.only(right: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
              image: DecorationImage(
                image: NetworkImage(product['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            product['name'],
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₺${product['price'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beğenebilirsiniz',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildRecommendationItem(0)),
                SizedBox(width: 8.w),
                Expanded(child: _buildRecommendationItem(1)),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(child: _buildRecommendationItem(2)),
                SizedBox(width: 8.w),
                Expanded(child: _buildRecommendationItem(3)),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
  
  Widget _buildRecommendationItem(int index) {
    // Mock data for recommendations
    final List<Map<String, dynamic>> recommendations = [
      {
        'image': 'https://via.placeholder.com/150/red',
        'name': 'Kırmızı Şık Üst',
        'price': 59.99,
      },
      {
        'image': 'https://via.placeholder.com/150/blue',
        'name': 'Mavi Yaz Elbisesi',
        'price': 69.99,
      },
      {
        'image': 'https://via.placeholder.com/150/purple',
        'name': 'Mor Kazak',
        'price': 49.99,
      },
      {
        'image': 'https://via.placeholder.com/150/brown',
        'name': 'Kahverengi Ceket',
        'price': 89.99,
      },
    ];
    
    final product = recommendations[index];
    
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
              image: DecorationImage(
                image: NetworkImage(product['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            product['name'],
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₺${product['price'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomActions() {
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
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: IconButton(
              icon: isLoadingFavorite
                  ? SizedBox(
                      width: 20.r, 
                      height: 20.r, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2.r,
                        color: Colors.red,
                      )
                    )
                  : Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.black,
                    ),
              onPressed: isLoadingFavorite ? null : _toggleFavorite,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: isAddingToCart ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: isAddingToCart
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.r,
                      ),
                    )
                  : Text(
                      'Sepete Ekle',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı metotlar
  void showCustomSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 