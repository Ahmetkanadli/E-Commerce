import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_commerce/core/repository/user_repository.dart';
import 'dart:developer' as developer;

class CardScreen extends StatefulWidget {
  final UserRepository userRepository;

  const CardScreen({
    super.key,
    required this.userRepository,
  });

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _validController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _validController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cardData = {
        'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
        'cardHolderName': _cardHolderController.text,
        'expiryDate': _validController.text,
        'cvv': _cvvController.text,
        'cardType': 'Visa', // Varsayılan olarak Visa
      };

      final result = await widget.userRepository.addCard(cardData);

      result.fold(
        (failure) {
          developer.log('🔴 Card addition failed: ${failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kart eklenemedi: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (card) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kart başarıyla eklendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // true döndürerek kartın eklendiğini bildir
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kart eklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRequiredLabel() {
    return Text(
      'Required',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 12.sp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Card'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                Text(
                  'Add Card',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 32.h),
                
                // Card Holder
                Text('Card Holder'),
                SizedBox(height: 4.h),
                _buildRequiredLabel(),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _cardHolderController,
                  decoration: InputDecoration(
                    hintText: 'Ad Soyad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kart sahibi adı gereklidir';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 24.h),
                
                // Card Number
                Text('Card Number'),
                SizedBox(height: 4.h),
                _buildRequiredLabel(),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    hintText: 'XXXX XXXX XXXX XXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kart numarası gereklidir';
                    }
                    if (value.replaceAll(' ', '').length < 16) {
                      return 'Geçerli bir kart numarası girin';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 24.h),
                
                // Valid & CVV in row
                Row(
                  children: [
                    // Valid (Expiry Date)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Valid'),
                          SizedBox(height: 4.h),
                          _buildRequiredLabel(),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _validController,
                            decoration: InputDecoration(
                              hintText: 'MM/YY',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Son kullanma tarihi gereklidir';
                              }
                              RegExp regExp = RegExp(r'^\d{2}/\d{2}$');
                              if (!regExp.hasMatch(value)) {
                                return 'MM/YY formatında girin';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    // CVV
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CVV'),
                          SizedBox(height: 4.h),
                          _buildRequiredLabel(),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _cvvController,
                            decoration: InputDecoration(
                              hintText: 'XXX',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'CVV gereklidir';
                              }
                              if (value.length < 3) {
                                return 'Geçerli bir CVV girin';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 40.h),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.w,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Varsayılan olarak kart sekmesi seçili
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Bag',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
} 