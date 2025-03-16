import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../views/payment_controller.dart';
import '../models/card_model.dart';
import '../widgets/card_formatters.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late final PaymentController _paymentController;

  @override
  void initState() {
    super.initState();
    _paymentController = PaymentController();
  }

  void _showAddCardDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddCardDialog(paymentController: _paymentController),
    );
  }

  void _showEditCardDialog(int index, CardModel card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCardDialog(
        paymentController: _paymentController,
        editIndex: index,
        existingCard: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider.value(
      value: _paymentController,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.paymentMethods,
            style: GoogleFonts.nunitoSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: Consumer<PaymentController>(
          builder: (context, controller, child) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.yourCards,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: Colors.white),
                          onPressed: _showAddCardDialog,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  if (controller.cards.isNotEmpty)
                    SizedBox(
                      height: 200.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.cards.length,
                        itemBuilder: (context, index) {
                          final card = controller.cards[index];
                          return _buildCardItem(index, card, l10n);
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.noCardsYet,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardItem(int index, CardModel card, AppLocalizations l10n) {
    return Container(
      width: 300.w,
      margin: EdgeInsets.only(right: 15.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[700]!,
            Colors.blue[900]!,
          ],
        ),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/mastercard_logo.png',
                width: 50.w,
                height: 50.h,
                color: Colors.white,
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showEditCardDialog(index, card),
              ),
            ],
          ),
          Spacer(),
          Text(
            card.maskedCardNumber,
            style: GoogleFonts.sourceCodePro(
              fontSize: 18.sp,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cardHolder,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    card.cardHolder,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.expires,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    card.expiryDate,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddCardDialog extends StatefulWidget {
  final PaymentController paymentController;
  final int? editIndex;
  final CardModel? existingCard;

  const AddCardDialog({
    Key? key,
    required this.paymentController,
    this.editIndex,
    this.existingCard,
  }) : super(key: key);

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existingCard != null) {
      _cardHolderController.text = widget.existingCard!.cardHolder;
      _cardNumberController.text = widget.existingCard!.cardNumber;
      _expiryController.text = widget.existingCard!.expiryDate;
      _cvvController.text = widget.existingCard!.cvv;
    }
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String? _validateCardHolder(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.cardHolderRequired;
    }
    if (value.length < 3) {
      return l10n.nameTooShort;
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.cardNumberRequired;
    }
    if (value.replaceAll(' ', '').length != 16) {
      return l10n.invalidCardNumber;
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.invalidFormat;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return l10n.invalidFormat;
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null || month < 1 || month > 12) {
      return l10n.invalidDate;
    }

    final now = DateTime.now();
    final cardDate = DateTime(2000 + year, month);
    if (cardDate.isBefore(now)) {
      return l10n.cardExpired;
    }

    return null;
  }

  String? _validateCVV(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.invalidFormat;
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return l10n.invalidFormat;
    }
    return null;
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final card = CardModel(
        cardHolder: _cardHolderController.text,
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryDate: _expiryController.text,
        cvv: _cvvController.text,
      );

      if (widget.editIndex != null) {
        widget.paymentController.updateCard(widget.editIndex!, card);
      } else {
        widget.paymentController.addCard(card);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingCard != null ? l10n.editCard : l10n.addCard,
                style: GoogleFonts.nunitoSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                l10n.cardHolder,
                _cardHolderController,
                validator: _validateCardHolder,
                formatters: [
                  CardHolderInputFormatter(),
                  LengthLimitingTextInputFormatter(50),
                ],
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 15.h),
              _buildTextField(
                l10n.cardNumber,
                _cardNumberController,
                validator: _validateCardNumber,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  CardNumberFormatter(),
                ],
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      l10n.valid,
                      _expiryController,
                      validator: _validateExpiry,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        ExpiryDateFormatter(),
                      ],
                      keyboardType: TextInputType.number,
                      hintText: 'MM/YY',
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: _buildTextField(
                      l10n.cvv,
                      _cvvController,
                      validator: _validateCVV,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    l10n.saveChanges,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? hintText,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          hintText: hintText,
          labelStyle: GoogleFonts.nunitoSans(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
          errorStyle: GoogleFonts.nunitoSans(
            fontSize: 12.sp,
            color: Colors.red,
          ),
        ),
        validator: validator,
        inputFormatters: formatters,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
      ),
    );
  }
}
