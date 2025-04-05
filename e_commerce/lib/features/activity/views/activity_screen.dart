import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:e_commerce/features/settings/views/settings_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/repository/product_repository.dart';
import 'package:e_commerce/features/products/models/product_model.dart';
import 'package:e_commerce/features/products/models/category_products.dart';
import 'dart:developer' as developer;
import 'package:e_commerce/features/products/views/product_detail_screen.dart';
import 'package:e_commerce/features/wishlist/views/wishlist_screen.dart';
import 'package:e_commerce/features/cart/views/cart_screen.dart';
import 'package:e_commerce/features/profile/views/profile_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<String> categories = ['Giyim', 'Elektronik', 'Spor', 'Kitap', 'Ev', 'Kozmetik'];
  final List<CategoryProducts> categoryProducts = [];
  bool isLoading = true;

  void _logInfo(String message) {
    developer.log('🔵 INFO: $message');
    print('🔵 INFO: $message');
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log('🔴 ERROR: $message', error: error, stackTrace: stackTrace);
    print('🔴 ERROR: $message');
    if (error != null) {
      print('Error details: $error');
    }
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void initState() {
    super.initState();
    _logInfo('ActivityScreen initialized');
    _loadCategoryProducts();
  }

  Future<void> _loadCategoryProducts() async {
    _logInfo('Starting to load category products');
    setState(() {
      isLoading = true;
    });

    final apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    final productRepository = ProductRepository(apiClient);
    
    _logInfo('API client and repository initialized');
    _logInfo('Base URL: ${ApiConstants.baseUrl}');
    _logInfo('Products by category endpoint: ${ApiConstants.productsByCategory}');

    for (final category in categories) {
      _logInfo('Loading products for category: $category');
      try {
        final endpoint = '${ApiConstants.productsByCategory}/$category';
        _logInfo('Making request to: $endpoint');
        
        final result = await productRepository.getProductsByCategory(category);
        result.fold(
          (failure) {
            _logError('Failed to load products for $category: ${failure.message}', failure);
          },
          (products) {
            _logInfo('Successfully loaded ${products.length} products for $category');
            setState(() {
              categoryProducts.add(
                CategoryProducts(category: category, products: products),
              );
            });
          },
        );
      } catch (e, stackTrace) {
        _logError('Exception occurred while loading $category', e, stackTrace);
      }
    }

    _logInfo('Finished loading all categories. Total loaded: ${categoryProducts.length}');
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building ActivityScreen');
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildAnnouncement(l10n),
                SizedBox(height: 24.h),
                _buildRecentlyViewed(l10n),
                SizedBox(height: 24.h),
                _buildMyOrders(l10n),
                SizedBox(height: 24.h),
                _buildStories(context),
                SizedBox(height: 24.h),
                _buildCategoryProductsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
            SizedBox(width: 12.w),
            Text(
              l10n.myActivity,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.copy_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.equalizer),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnouncement(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.announcement,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.announcementText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16.sp),
        ],
      ),
    );
  }

  Widget _buildCategoryProductsSection() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.popularProducts,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        ...categoryProducts.map((categoryProduct) => _buildCategoryRow(categoryProduct)).toList(),
      ],
    );
  }

  Widget _buildCategoryRow(CategoryProducts categoryProduct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            categoryProduct.category,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryProduct.products.length,
            itemBuilder: (context, index) {
              final product = categoryProduct.products[index];
              return _buildProductCard(product);
            },
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 150.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Gallery
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.r),
                topRight: Radius.circular(10.r),
              ),
              child: SizedBox(
                height: 120.h,
                child: product.images.isEmpty
                  ? _buildPlaceholderImage()
                  : product.images.length == 1
                    ? _buildSingleImage(product.images.first)
                    : _buildImageGallery(product.images),
              ),
            ),
            // Product Info
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '₺${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
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
  
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
  
  Widget _buildSingleImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }
  
  Widget _buildImageGallery(List<String> images) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            // Image
            SizedBox(
              width: double.infinity,
              child: Image.network(
                images[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              ),
            ),
            // Page indicator
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${index + 1}/${images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentlyViewed(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentlyViewed,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              5,
              (index) => Container(
                margin: EdgeInsets.only(right: 12.w),
                child: CircleAvatar(
                  radius: 30.r,
                  backgroundColor: Colors.primaries[index % Colors.primaries.length].withOpacity(0.2),
                  child: Icon(
                    Icons.image,
                    color: Colors.primaries[index % Colors.primaries.length],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyOrders(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myOrders,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _buildOrderButton(l10n.toPay, Colors.blue[50]!),
            SizedBox(width: 12.w),
            _buildOrderButton(l10n.toReceive, Colors.blue[50]!),
            SizedBox(width: 12.w),
            _buildOrderButton(l10n.toReview, Colors.blue[50]!),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderButton(String text, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildStories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stories,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              4,
              (index) => Container(
                margin: EdgeInsets.only(right: 12.w),
                width: 140.w,
                height: 200.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: Colors.primaries[(index + 5) % Colors.primaries.length].withOpacity(0.3),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 50.r,
                        color: Colors.white,
                      ),
                    ),
                    if (index == 0)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: EdgeInsets.all(8.r),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            l10n.live,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
