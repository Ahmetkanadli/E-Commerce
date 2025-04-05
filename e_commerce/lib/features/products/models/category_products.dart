import 'package:e_commerce/features/products/models/product_model.dart';

class CategoryProducts {
  final String category;
  final List<ProductModel> products;

  CategoryProducts({
    required this.category,
    required this.products,
  });
} 