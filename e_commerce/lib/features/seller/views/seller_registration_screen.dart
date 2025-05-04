import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/cache/cache_manager.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<File> _documents = [];
  String _documentType = 'taxDocument'; // Varsayılan belge türü

  final List<String> _documentTypes = [
    'taxDocument',
    'identityDocument',
    'businessLicense',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    // Varsayılan ülke değeri
    _countryController.text = 'Türkiye';
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _documents.add(File(result.files.single.path!));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçme hatası: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        setState(() {
          _documents.add(File(pickedImage.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçme hatası: $e')),
      );
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir belge yüklemelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // JWT token'ı al
      final token = await CacheManager.getToken();
      if (token == null) {
        throw Exception('Oturum açmanız gerekiyor');
      }

      // Dosya yollarını listeye al - @ işaretini kaldırıyorum
      final List<String> documentPaths = _documents.map((file) => file.path).toList();
      
      // API'ye gönderilecek JSON verisi - adres bilgilerini düzgün JSON olarak formatlıyoruz
      final Map<String, dynamic> requestData = {
        'shopName': _shopNameController.text,
        'description': _descriptionController.text,
        'phone': _phoneController.text,
        'address': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zipCode': _zipCodeController.text,
          'country': _countryController.text,
        },
        'documentType': _documentType,
        'documents': documentPaths,
      };

      print('Gönderilen veri: ${requestData}'); // Debug için

      // API isteği gönder
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.registerAsSeller}',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          }
        ),
      );

      print('API yanıtı: ${response.statusCode} - ${response.data}'); // Debug için

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Başvurunuz başarıyla alındı. İnceleme sonrası size bilgi verilecektir.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Başvuru gönderilirken bir hata oluştu: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satıcı Başvurusu'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Satıcı Olmak İçin Başvuru Formu',
                style: GoogleFonts.raleway(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: 'Mağaza Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mağaza adı zorunludur';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon numarası zorunludur';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // Adres alanları
              Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 8.h),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
                        child: Text(
                          'Adres Bilgileri',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _streetController,
                        decoration: const InputDecoration(
                          labelText: 'Sokak/Cadde',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Sokak/Cadde bilgisi zorunludur';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'Şehir',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Şehir zorunludur';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'İlçe',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'İlçe zorunludur';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _zipCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Posta Kodu',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Posta kodu zorunludur';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Ülke',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ülke zorunludur';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'İş Tanımı / Ne Satmak İstiyorsunuz?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'İş tanımı zorunludur';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // Belge türü seçimi
              DropdownButtonFormField<String>(
                value: _documentType,
                decoration: const InputDecoration(
                  labelText: 'Belge Türü',
                  border: OutlineInputBorder(),
                ),
                items: _documentTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(_getDocumentTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _documentType = newValue;
                    });
                  }
                },
              ),
              
              SizedBox(height: 16.h),
              
              // Belge yükleme bölümü
              Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 8.h),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
                        child: Text(
                          'Belgeler (${_documents.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickDocument,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Belge Ekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Görsel Ekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      
                      // Yüklenen belgelerin listesi
                      if (_documents.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final fileName = _documents[index].path.split('/').last;
                            return ListTile(
                              leading: _getFileIcon(_documents[index].path),
                              title: Text(
                                fileName,
                                style: TextStyle(fontSize: 14.sp),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeDocument(index),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004CFF),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Başvuru Yap',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
              ),
              SizedBox(height: 16.h),
              const Text(
                'Not: Başvurunuz incelendikten sonra tarafınıza bilgi verilecektir. '
                'Onay alındıktan sonra ürünlerinizi yüklemeye başlayabilirsiniz.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Belge türünü etiketini döndüren yardımcı fonksiyon
  String _getDocumentTypeLabel(String type) {
    switch (type) {
      case 'taxDocument':
        return 'Vergi Levhası';
      case 'identityDocument':
        return 'Kimlik Belgesi';
      case 'businessLicense':
        return 'İşyeri Ruhsatı';
      case 'other':
        return 'Diğer';
      default:
        return type;
    }
  }
  
  // Dosya türüne göre simge döndüren yardımcı fonksiyon
  Widget _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    
    if (extension == 'pdf') {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return const Icon(Icons.image, color: Colors.green);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.blue);
    }
  }
} 