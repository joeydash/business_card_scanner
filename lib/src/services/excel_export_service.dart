import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/business_card_data.dart';

class ExcelExportService {
  // Export business cards to Excel and return file info for sharing
  Future<Map<String, dynamic>> exportToExcel(List<BusinessCardData> cards) async {
    final excel = Excel.createExcel();
    final sheet = excel['Business Cards'];
    
    // First pass: Find maximum counts for each list field
    int maxEmails = 0;
    int maxPhones = 0;
    int maxWebsites = 0;
    
    for (var card in cards) {
      if (card.emails.length > maxEmails) maxEmails = card.emails.length;
      if (card.phones.length > maxPhones) maxPhones = card.phones.length;
      if (card.websites.length > maxWebsites) maxWebsites = card.websites.length;
    }
    
    // Build header row with dynamic columns
    List<String> headers = [
      'Person Name',
      'Job Title',
      'Pronouns',
    ];
    
    // Add email columns
    for (int i = 1; i <= maxEmails; i++) {
      headers.add(i == 1 ? 'Email' : 'Email_$i');
    }
    
    // Add phone columns
    for (int i = 1; i <= maxPhones; i++) {
      headers.add(i == 1 ? 'Phone' : 'Phone_$i');
    }
    
    // Add website columns
    for (int i = 1; i <= maxWebsites; i++) {
      headers.add(i == 1 ? 'Website' : 'Website_$i');
    }
    
    // Add remaining single-value columns
    headers.addAll([
      'LinkedIn',
      'Twitter',
      'Company Name',
      'Department',
      'Address',
      'City',
      'State',
      'Postal Code',
      'Country',
      'Fax',
      'Tagline',
      'Raw Text',
    ]);
    
    // Write headers
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }
    
    // Write data rows
    for (int rowIndex = 0; rowIndex < cards.length; rowIndex++) {
      final card = cards[rowIndex];
      int colIndex = 0;
      
      // Person Name
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.personName);
      
      // Job Title
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.jobTitle);
      
      // Pronouns
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.pronouns);
      
      // Emails
      for (int i = 0; i < maxEmails; i++) {
        _setCellValue(
          sheet,
          colIndex++,
          rowIndex + 1,
          i < card.emails.length ? card.emails[i] : null,
        );
      }
      
      // Phones
      for (int i = 0; i < maxPhones; i++) {
        _setCellValue(
          sheet,
          colIndex++,
          rowIndex + 1,
          i < card.phones.length ? card.phones[i] : null,
        );
      }
      
      // Websites
      for (int i = 0; i < maxWebsites; i++) {
        _setCellValue(
          sheet,
          colIndex++,
          rowIndex + 1,
          i < card.websites.length ? card.websites[i] : null,
        );
      }
      
      // LinkedIn
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.linkedIn);
      
      // Twitter
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.twitter);
      
      // Company Name
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.companyName);
      
      // Department
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.department);
      
      // Address
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.address);
      
      // City
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.city);
      
      // State
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.state);
      
      // Postal Code
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.postalCode);
      
      // Country
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.country);
      
      // Fax
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.fax);
      
      // Tagline
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.tagline);
      
      // Raw Text
      _setCellValue(sheet, colIndex++, rowIndex + 1, card.rawText);
    }
    
    // Generate the file
    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file');
    }
    
    // Save to temporary directory for sharing
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'business_cards_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    
    return {
      'path': filePath,
      'bytes': Uint8List.fromList(fileBytes),
      'fileName': fileName,
    };
  }
  
  void _setCellValue(Sheet sheet, int colIndex, int rowIndex, String? value) {
    if (value != null && value.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex))
          .value = TextCellValue(value);
    }
  }
}
