import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_card_data.dart';

class CardStorageService {
  static const String _cardsKey = 'scanned_cards';
  
  // Save a new business card
  Future<void> saveCard(BusinessCardData card) async {
    final prefs = await SharedPreferences.getInstance();
    final cards = await getAllCards();
    cards.add(card);
    
    final cardsJson = cards.map((card) => card.toJson()).toList();
    await prefs.setString(_cardsKey, jsonEncode(cardsJson));
  }
  
  // Get all saved cards
  Future<List<BusinessCardData>> getAllCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsString = prefs.getString(_cardsKey);
    
    if (cardsString == null) {
      return [];
    }
    
    final List<dynamic> cardsJson = jsonDecode(cardsString);
    return cardsJson.map((json) => BusinessCardData.fromJson(json)).toList();
  }
  
  // Delete a card by index
  Future<void> deleteCard(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final cards = await getAllCards();
    
    if (index >= 0 && index < cards.length) {
      cards.removeAt(index);
      final cardsJson = cards.map((card) => card.toJson()).toList();
      await prefs.setString(_cardsKey, jsonEncode(cardsJson));
    }
  }
  
  // Clear all cards
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cardsKey);
  }
  
  // Get card count
  Future<int> getCardCount() async {
    final cards = await getAllCards();
    return cards.length;
  }
}
