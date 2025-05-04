import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_commerce/features/auth/views/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/repository/user_repository.dart';
import 'package:e_commerce/core/models/card_model.dart';
import 'package:e_commerce/core/models/user_model.dart';
import 'dart:developer' as developer;
import 'package:e_commerce/core/cache/cache_manager.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  List<CardModel> _userCards = [];
  UserModel? _userProfile;
  
  late UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ApiClient apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
      
      // Get auth token from cache and set it in ApiClient
      final authToken = await CacheManager.getToken();
      if (authToken != null) {
        apiClient.setToken(authToken);
        developer.log('✅ Profile screen: Auth token set from cache');
      } else {
        developer.log('⚠️ Profile screen: No auth token found in cache');
        // If there's no token, redirect to login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
      }
      
      _userRepository = UserRepository(apiClient);
      
      _loadUserProfile();
      _loadUserCards();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    developer.log('🔍 Profil yükleniyor...');
    
    try {
      final result = await _userRepository.getUserProfile();
      
      developer.log('🔍 getUserProfile sonucu alındı. Either türü: ${result.runtimeType}');
      
      result.fold(
        (failure) {
          developer.log('🔴 Profile load failed: ${failure.message}, Status code: ${failure.statusCode}');
          _showMessage('Kullanıcı bilgileri alınamadı: ${failure.message}', isError: true);
        },
        (userProfile) {
          developer.log('✅ Profil yüklendi');
          developer.log('✅ UserModel içeriği: id=${userProfile.id}, name=${userProfile.name}, email=${userProfile.email}, role=${userProfile.role}');
          developer.log('✅ Address: ${userProfile.address}');
          developer.log('✅ Favorites: ${userProfile.favorites.length} ürün');
          developer.log('✅ Stats: ${userProfile.stats}');
          
          setState(() {
            _userProfile = userProfile;
            _nameController.text = userProfile.name;
            _emailController.text = userProfile.email;
          });
        },
      );
    } catch (e, stackTrace) {
      developer.log('⚠️ Profil yüklenirken hata oluştu', error: e, stackTrace: stackTrace);
      _showMessage('Beklenmeyen bir hata oluştu', isError: true);
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _loadUserCards() async {
    final result = await _userRepository.getUserCards();
    
    result.fold(
      (failure) {
        developer.log('🔴 Cards load failed: ${failure.message}');
      },
      (cards) {
        setState(() {
          _userCards = cards;
        });
        developer.log('✅ Loaded ${cards.length} cards');
      },
    );
  }
  
  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showMessage('İsim alanı boş olamaz', isError: true);
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    final userData = {
      'name': _nameController.text,
    };
    
    final result = await _userRepository.updateUserProfile(userData);
    
    result.fold(
      (failure) {
        developer.log('🔴 Profile update failed: ${failure.message}');
        _showMessage('Profil güncellenemedi', isError: true);
      },
      (userProfile) {
        setState(() {
          _userProfile = userProfile;
        });
        _showMessage('Profil başarıyla güncellendi');
        developer.log('✅ Profile updated successfully');
      },
    );
    
    setState(() {
      _isSaving = false;
    });
  }
  
  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty || 
        _newPasswordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Tüm şifre alanları doldurulmalı', isError: true);
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('Yeni şifreler eşleşmiyor', isError: true);
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    final result = await _userRepository.updatePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );
    
    result.fold(
      (failure) {
        developer.log('🔴 Password update failed: ${failure.message}');
        _showMessage('Şifre güncellenemedi', isError: true);
      },
      (_) {
        _showMessage('Şifre başarıyla güncellendi');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        developer.log('✅ Password updated successfully');
      },
    );
    
    setState(() {
      _isSaving = false;
    });
  }
  
  Future<void> _deleteAccount() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hesabı Sil'),
        content: Text('Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await _userRepository.deleteUserAccount();
    
    result.fold(
      (failure) {
        developer.log('🔴 Account deletion failed: ${failure.message}');
        _showMessage('Hesap silinemedi', isError: true);
        setState(() {
          _isLoading = false;
        });
      },
      (_) {
        _showMessage('Hesabınız silindi');
        // Kullanıcıyı çıkış yapmaya yönlendir
        context.read<AuthController>().logout();
        Navigator.of(context).pushReplacementNamed('/login');
      },
    );
  }
  
  Future<void> _addCard() async {
    final _cardHolderController = TextEditingController();
    final _cardNumberController = TextEditingController();
    final _validController = TextEditingController();
    final _cvvController = TextEditingController();
    bool _isLoading = false;
    final _formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16.w, 
            right: 16.w,
            top: 20.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.h
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Title and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Card',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Card Holder
                  Text('Card Holder'),
                  SizedBox(height: 4.h),
                  Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12.sp,
                    ),
                  ),
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
                  Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12.sp,
                    ),
                  ),
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
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
                            Text(
                              'Required',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                              ),
                            ),
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
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _ExpiryDateFormatter(),
                              ],
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
                            Text(
                              'Required',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                              ),
                            ),
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
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
                      onPressed: _isLoading 
                        ? null 
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
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
                                
                                final result = await _userRepository.addCard(cardData);
                                
                                result.fold(
                                  (failure) {
                                    developer.log('🔴 Card addition failed: ${failure.message}');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Kart eklenemedi: ${failure.message}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    Navigator.pop(context, false);
                                  },
                                  (card) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Kart başarıyla eklendi'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  },
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Kart eklenirken hata oluştu: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                Navigator.pop(context, false);
                              }
                            }
                          },
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
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    if (result == true) {
      _loadUserCards();
    }
  }
  
  Future<void> _updateCard(CardModel card) async {
    final cardNumberController = TextEditingController(text: card.cardNumber);
    final cardHolderNameController = TextEditingController(text: card.cardHolderName);
    final expiryDateController = TextEditingController(text: card.expiryDate);
    final nicknameController = TextEditingController(text: card.nickname);
    
    final cardTypes = ['Visa', 'MasterCard', 'American Express', 'Discover', 'Diğer'];
    String selectedCardType = cardTypes.contains(card.cardType) ? card.cardType : cardTypes[0];
    
    final formKey = GlobalKey<FormState>();
    
    bool result = await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Kartı Düzenle'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCardType,
                    decoration: InputDecoration(
                      labelText: 'Kart Tipi',
                      border: OutlineInputBorder(),
                    ),
                    items: cardTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCardType = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: nicknameController,
                    decoration: InputDecoration(
                      labelText: 'Kart Takma Adı (İsteğe Bağlı)',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: İş Kartım',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text('Güncelle'),
            ),
          ],
        ),
      ),
    ) ?? false;
    
    if (!result) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cardData = {
        'cardType': selectedCardType,
        'nickname': nicknameController.text,
      };
      
      final result = await _userRepository.updateCard(card.id, cardData);
      
      result.fold(
        (failure) {
          developer.log('🔴 Card update failed: ${failure.message}');
          _showMessage('Kart güncellenemedi: ${failure.message}', isError: true);
        },
        (updatedCard) {
          _showMessage('Kart başarıyla güncellendi');
      _loadUserCards();
        },
      );
    } catch (e) {
      _showMessage('Kart güncellenirken hata oluştu: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteCard(String cardId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kartı Sil'),
        content: Text('Bu kartı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await _userRepository.deleteCard(cardId);
    
    result.fold(
      (failure) {
        developer.log('🔴 Card deletion failed: ${failure.message}');
        _showMessage('Kart silinemedi', isError: true);
      },
      (_) {
        _showMessage('Kart başarıyla silindi');
        _loadUserCards();
      },
    );
    
    setState(() {
      _isLoading = false;
    });
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.settings,
          style: GoogleFonts.nunitoSans(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          // Debug bilgisi göstermek için bir buton ekle
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.grey),
            onPressed: () {
              _showDebugInfo();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: 'Profil'),
            Tab(text: 'Kartlarım'),
            Tab(text: 'Favoriler'),
          ],
        ),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(l10n),
              _buildCardsTab(l10n),
              _buildFavoritesTab(l10n),
            ],
          ),
    );
  }

  Widget _buildProfileTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      _userProfile?.name.isNotEmpty == true
                          ? _userProfile!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            
            // Kullanıcı rolleri ve durumu
            Center(
              child: Column(
                children: [
                  Text(
                    _userProfile?.name ?? 'Kullanıcı',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _userProfile?.role == 'seller' ? Colors.purple[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _userProfile?.role == 'seller' ? 'Satıcı' : 'Müşteri',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _userProfile?.role == 'seller' ? Colors.purple : Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _userProfile?.emailVerified == true ? Colors.green[100] : Colors.amber[100],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _userProfile?.emailVerified == true ? 'E-posta Doğrulandı' : 'Doğrulanmamış',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _userProfile?.emailVerified == true ? Colors.green : Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30.h),
            
            // İstatistikler
            if (_userProfile?.stats != null) ...[
              _buildStatsCard(),
              SizedBox(height: 30.h),
            ],
            
            // Temel bilgiler
            Text(
              'Profil Bilgileri',
              style: GoogleFonts.nunitoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            _buildTextField(l10n.name, _nameController),
            SizedBox(height: 20.h),
            _buildTextField(l10n.email, _emailController, enabled: false),
            
            // Adres bilgisi
            if (_userProfile?.address != null) ...[
              SizedBox(height: 20.h),
              _buildAddressField(),
            ],
            
            SizedBox(height: 40.h),
            
            // Profil bilgilerini güncelleme butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: _isSaving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      l10n.saveChanges,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
            
            SizedBox(height: 30.h),
            
            // Şifre değiştirme bölümü
            Text(
              'Şifre Değiştir',
              style: GoogleFonts.nunitoSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            _buildTextField('Mevcut Şifre', _currentPasswordController, isPassword: true),
            SizedBox(height: 15.h),
            _buildTextField('Yeni Şifre', _newPasswordController, isPassword: true),
            SizedBox(height: 15.h),
            _buildTextField('Yeni Şifre (Tekrar)', _confirmPasswordController, isPassword: true),
            SizedBox(height: 20.h),
            
            // Şifre güncelleme butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: _isSaving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Şifreyi Güncelle',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
            
            SizedBox(height: 40.h),
            
            // Hesabı silme butonu
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                ),
                child: Text(
                  'Hesabımı Sil',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsTab(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kayıtlı Kartlarım',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: _addCard,
                tooltip: 'Yeni Kart Ekle',
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Kart listesi
          Expanded(
            child: _userCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_outlined,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Henüz kayıtlı kart bulunamadı',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ElevatedButton(
                        onPressed: _addCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        ),
                        child: Text('Kart Ekle'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _userCards.length,
                  itemBuilder: (context, index) {
                    final card = _userCards[index];
                    return _buildCardItem(card);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(CardModel card) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.nickname.isEmpty ? 'Kartım' : card.nickname,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  card.cardType,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              card.maskedCardNumber,
              style: TextStyle(
                fontSize: 18.sp,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Kullanma: ${card.expiryDate}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20.r),
                      onPressed: () => _updateCard(card),
                      tooltip: 'Düzenle',
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.all(8.r),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20.r, color: Colors.red),
                      onPressed: () => _deleteCard(card.id),
                      tooltip: 'Sil',
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.all(8.r),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false, bool enabled = true}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        enabled: enabled,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.nunitoSans(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _userProfile?.stats;
    if (stats == null) return SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İstatistikler',
              style: GoogleFonts.nunitoSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.shopping_bag_outlined,
                  value: stats['ordersCount']?.toString() ?? '0',
                  label: 'Sipariş',
                ),
                _buildStatItem(
                  icon: Icons.pending_actions_outlined,
                  value: stats['activeOrdersCount']?.toString() ?? '0',
                  label: 'Aktif Sipariş',
                ),
                _buildStatItem(
                  icon: Icons.favorite_border_outlined,
                  value: stats['favoritesCount']?.toString() ?? '0',
                  label: 'Favori',
                ),
                _buildStatItem(
                  icon: Icons.credit_card_outlined,
                  value: stats['savedCardsCount']?.toString() ?? '0',
                  label: 'Kart',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.nunitoSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddressField() {
    final address = _userProfile?.address;
    if (address == null) return SizedBox.shrink();
    
    String addressText = '';
    if (address.containsKey('country')) {
      addressText = address['country'] as String? ?? '';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: addressText),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: 'Ülke',
          labelStyle: GoogleFonts.nunitoSans(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    final String productId = favorite['_id'] ?? '';
    final String name = favorite['name'] ?? '';
    final double price = favorite['price'] is num ? (favorite['price'] as num).toDouble() : 0.0;
    final List<String> images = [];
    
    if (favorite['images'] is List) {
      for (var img in favorite['images']) {
        if (img is String) {
          images.add(img);
        }
      }
    }
    
    // SizedBox ile dışarıdan boyutu kontrol ediyoruz
    return SizedBox(
      height: 240.h, // Kartın yüksekliğini sabit tutuyoruz
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün görseli - yüksekliği sabit tutuyoruz
            SizedBox(
              height: 140.h,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  topRight: Radius.circular(10.r),
                ),
                child: images.isNotEmpty
                  ? Image.network(
                      images[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[600]),
                          alignment: Alignment.center,
                        ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[600]),
                      alignment: Alignment.center,
                    ),
              ),
            ),
            
            // Ürün bilgileri - kalan yüksekliği kullanıyor
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ürün adı - en fazla 2 satır
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Fiyat bilgisi - alt kısımda
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 6.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '${price.toStringAsFixed(2)} TL',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFavoritesTab(AppLocalizations l10n) {
    final favorites = _userProfile?.favorites ?? [];
    
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Favori Ürünlerim',
            style: GoogleFonts.nunitoSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Favori ürünler listesi
          Expanded(
            child: favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Henüz favori ürün eklenmemiş',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Ekran genişliğine göre ızgara sütun sayısını hesapla
                    final double itemWidth = (constraints.maxWidth - 10.w) / 2; // 2 sütun, 10.w boşluk
                    
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: itemWidth / 240.h, // Genişlik/yükseklik oranı
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 15.h,
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        return _buildFavoriteItem(favorites[index]);
                      },
                    );
                  }
                ),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Bilgisi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('UserProfile Durumu: ${_userProfile != null ? "Yüklendi" : "Yüklenmedi"}'),
              SizedBox(height: 8),
              if (_userProfile != null) ...[
                Text('ID: ${_userProfile!.id}'),
                Text('İsim: ${_userProfile!.name}'),
                Text('E-posta: ${_userProfile!.email}'),
                Text('Rol: ${_userProfile!.role}'),
                Text('E-posta Doğrulandı: ${_userProfile!.emailVerified}'),
                Text('Adres: ${_userProfile!.address}'),
                Text('Favoriler: ${_userProfile!.favorites.length} ürün'),
                Text('Favoriler İçerik: ${_userProfile!.favorites}'),
                Text('İstatistikler: ${_userProfile!.stats}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadUserProfile(); // Profili yeniden yükle
            },
            child: Text('Yenile'),
          ),
        ],
      ),
    );
  }
}

// Kart numarası formatla
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Son kullanma tarihi formatla MM/YY
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length && nonZeroIndex != 4) {
        buffer.write('/');
      }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
