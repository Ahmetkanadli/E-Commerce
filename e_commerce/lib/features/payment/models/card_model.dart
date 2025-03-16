class CardModel {
  final String cardHolder;
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  CardModel({
    required this.cardHolder,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
  });

  String get maskedCardNumber {
    final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $lastFourDigits';
  }

  Map<String, dynamic> toJson() {
    return {
      'cardHolder': cardHolder,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
    };
  }

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardHolder: json['cardHolder'],
      cardNumber: json['cardNumber'],
      expiryDate: json['expiryDate'],
      cvv: json['cvv'],
    );
  }
}
