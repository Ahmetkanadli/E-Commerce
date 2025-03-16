import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';

class PaymentController extends ChangeNotifier {
  List<CardModel> _cards = [];
  List<CardModel> get cards => _cards;

  PaymentController() {
    _loadCards();
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = prefs.getStringList('cards') ?? [];
    _cards = cardsJson
        .map((cardJson) => CardModel.fromJson(json.decode(cardJson)))
        .toList();
    notifyListeners();
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = _cards.map((card) => json.encode(card.toJson())).toList();
    await prefs.setStringList('cards', cardsJson);
  }

  void addCard(CardModel card) {
    _cards.add(card);
    _saveCards();
    notifyListeners();
  }

  void updateCard(int index, CardModel card) {
    if (index >= 0 && index < _cards.length) {
      _cards[index] = card;
      _saveCards();
      notifyListeners();
    }
  }

  void deleteCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _cards.removeAt(index);
      _saveCards();
      notifyListeners();
    }
  }
}
