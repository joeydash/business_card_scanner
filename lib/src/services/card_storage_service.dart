import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_card_data.dart';
import 'database_helper.dart';

class CardStorageService {
  static const String _cardsKey = 'scanned_cards';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Initialize and migrate if needed
  Future<void> init() async {
    await _migrateFromSharedPreferences();
  }

  // Migrate data from SharedPreferences to SQLite
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsString = prefs.getString(_cardsKey);
    
    if (cardsString != null) {
      try {
        final List<dynamic> cardsJson = jsonDecode(cardsString);
        final cards = cardsJson.map((json) => BusinessCardData.fromJson(json)).toList();
        
        // Insert all cards into SQLite
        for (final card in cards) {
          // Ensure scannedAt is set during migration
          final cardToSave = card.scannedAt == null 
              ? card.copyWith(scannedAt: DateTime.now()) 
              : card;
          await _dbHelper.create(cardToSave);
        }
        
        // Clear SharedPreferences after successful migration
        await prefs.remove(_cardsKey);
        debugPrint('Successfully migrated ${cards.length} cards to SQLite');
      } catch (e) {
        debugPrint('Error migrating cards: $e');
      }
    }
  }
  
  // Save a new business card
  Future<void> saveCard(BusinessCardData card) async {
    // Ensure scannedAt is set
    final cardToSave = card.scannedAt == null 
        ? card.copyWith(scannedAt: DateTime.now()) 
        : card;
        
    await _dbHelper.create(cardToSave);
  }
  
  // Get all saved cards
  Future<List<BusinessCardData>> getAllCards() async {
    // Check for migration on first load
    await _migrateFromSharedPreferences();
    return await _dbHelper.readAllCards();
  }

  // Get cards with pagination for lazy loading
  Future<List<BusinessCardData>> getCardsPaginated({
    required int limit,
    required int offset,
  }) async {
    // Check for migration on first load
    await _migrateFromSharedPreferences();
    return await _dbHelper.readCardsPaginated(limit: limit, offset: offset);
  }

  // Get total count of cards
  Future<int> getCardCount() async {
    await _migrateFromSharedPreferences();
    return await _dbHelper.getCardCount();
  }
  
  // Delete a card by ID
  Future<void> deleteCard(int id) async {
    await _dbHelper.delete(id);
  }
  
  // Update a card
  Future<void> updateCard(BusinessCardData updatedCard) async {
    if (updatedCard.id != null) {
      await _dbHelper.update(updatedCard, updatedCard.id!);
    }
  }
  
  // Clear all cards
  Future<void> clearAll() async {
    await _dbHelper.deleteAll();
  }
}
