import 'package:e_commerce/features/auth/views/auth_controller.dart';
import 'package:e_commerce/core/repository/auth_repository.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/features/auth/views/login_page.dart';
import 'package:e_commerce/features/profile/views/profile_screen.dart';
import 'package:e_commerce/features/payment/views/payment_methods_screen.dart';
import 'package:e_commerce/features/seller/views/seller_registration_screen.dart';
import 'package:e_commerce/features/onboarding/views/welcome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    final authRepository = AuthRepository(apiClient);
    _authController = AuthController(authRepository);
  }

  Future<void> _handleLogout() async {
    await _authController.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _authController,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.settings),
            elevation: 0,
          ),
          body: ListView(
            children: [
              _buildSectionHeader(l10n.personal),
              ListTile(
                title: Text(l10n.profile),
                leading: const Icon(Icons.person_outline),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: _authController,
                        child: const ProfileScreen(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(l10n.shippingAddress),
                leading: const Icon(Icons.location_on_outlined),
                onTap: () {},
              ),
              ListTile(
                title: Text(l10n.paymentMethods),
                leading: const Icon(Icons.payment_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildSectionHeader(l10n.shop),
              ListTile(
                title: Text(l10n.becomeSeller),
                leading: const Icon(Icons.store),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showSellerDialog(context);
                },
              ),
              ListTile(
                title: Text(l10n.country),
                leading: const Icon(Icons.public),
                onTap: () {},
              ),
              ListTile(
                title: Text(l10n.currency),
                leading: const Icon(Icons.currency_exchange),
                onTap: () {},
              ),
              ListTile(
                title: Text(l10n.sizes),
                leading: const Icon(Icons.straighten),
                onTap: () {},
              ),
              ListTile(
                title: Text(l10n.termsAndConditions),
                leading: const Icon(Icons.description_outlined),
                onTap: () {},
              ),
              const Divider(),
              _buildSectionHeader(l10n.account),
              ListTile(
                title: Text(l10n.language),
                leading: const Icon(Icons.language),
                onTap: () {},
              ),
              ListTile(
                title: Text(l10n.about),
                leading: const Icon(Icons.info_outline),
                onTap: () {},
              ),
              const Divider(),
              _buildSectionHeader('Slada'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.version,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  l10n.deleteAccount,
                  style: const TextStyle(color: Colors.red),
                ),
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: () {
                  // Hesap silme işlemi
                },
              ),
              ListTile(
                title: Text(
                  l10n.logout,
                  style: const TextStyle(color: Colors.red),
                ),
                leading: const Icon(Icons.logout, color: Colors.red),
                onTap: _handleLogout,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSellerDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.becomeSeller),
        content: const Text("Satıcı olmak ve ürünlerinizi satmak için başvuru yapın. Başvurunuz onaylandıktan sonra ürün yüklemeye başlayabilirsiniz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Satıcı başvuru sayfasına yönlendirme
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const SellerRegistrationScreen()),
              );
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
