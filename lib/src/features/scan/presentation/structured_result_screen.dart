import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/business_card_data.dart';
import '../../../services/card_storage_service.dart';

class StructuredResultScreen extends StatefulWidget {
  final BusinessCardData data;

  const StructuredResultScreen({super.key, required this.data});

  @override
  State<StructuredResultScreen> createState() => _StructuredResultScreenState();
}

class _StructuredResultScreenState extends State<StructuredResultScreen> {
  final CardStorageService _storageService = CardStorageService();
  bool _isSaving = false;

  Future<void> _saveCard() async {
    setState(() => _isSaving = true);
    try {
      await _storageService.saveCard(widget.data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved successfully!')),
        );
        // Return to home screen with success flag
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Business Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy All Data',
            onPressed: () => _copyAllData(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Parsed Fields Section
            _buildSectionHeader('Parsed Information'),
            _buildParsedFields(),
            
            const SizedBox(height: 16),
            
            // Raw Text Section
            _buildSectionHeader('Original OCR Text'),
            _buildRawTextCard(),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveCard,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Card'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildParsedFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Personal Information
          _buildFieldCard('👤 Person Name', widget.data.personName),
          _buildFieldCard('💼 Job Title', widget.data.jobTitle),
          _buildFieldCard('🏷️ Pronouns', widget.data.pronouns),
          
          // Contact Information
          _buildListFieldCard('📧 Email', widget.data.emails),
          _buildListFieldCard('📱 Phone', widget.data.phones),
          _buildListFieldCard('🌐 Website', widget.data.websites),
          _buildFieldCard('💼 LinkedIn', widget.data.linkedIn),
          _buildFieldCard('🐦 Twitter', widget.data.twitter),
          
          // Company Information
          _buildFieldCard('🏢 Company Name', widget.data.companyName),
          _buildFieldCard('🏛️ Department', widget.data.department),
          _buildFieldCard('📍 Address', widget.data.address),
          _buildFieldCard('🏙️ City', widget.data.city),
          _buildFieldCard('🗺️ State', widget.data.state),
          _buildFieldCard('📮 Postal Code', widget.data.postalCode),
          _buildFieldCard('🌍 Country', widget.data.country),
          
          // Additional
          _buildFieldCard('📠 Fax', widget.data.fax),
          _buildFieldCard('💬 Tagline', widget.data.tagline),
        ],
      ),
    );
  }

  Widget _buildFieldCard(String label, String? value) {
    if (value == null || value.isEmpty) {
      return _buildNullField(label);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(value, label),
        ),
      ),
    );
  }

  Widget _buildListFieldCard(String label, List<String> values) {
    if (values.isEmpty) {
      return _buildNullField(label);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          values.length == 1 ? values[0] : '${values.length} items',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        children: values.map((value) => ListTile(
          title: Text(value),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyToClipboard(value, label),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNullField(String label) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: Colors.grey.shade100,
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        subtitle: const Text(
          'Not detected',
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildRawTextCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Full Text',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(widget.data.rawText, 'Raw Text'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.data.rawText.isEmpty ? 'No text detected' : widget.data.rawText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    // Note: Can't show SnackBar without BuildContext in StatelessWidget
    // Would need to pass context or use a different approach
  }

  void _copyAllData(BuildContext context) {
    final buffer = StringBuffer();
    
    if (widget.data.personName != null) buffer.writeln('Name: ${widget.data.personName}');
    if (widget.data.jobTitle != null) buffer.writeln('Title: ${widget.data.jobTitle}');
    if (widget.data.companyName != null) buffer.writeln('Company: ${widget.data.companyName}');
    if (widget.data.emails.isNotEmpty) buffer.writeln('Email: ${widget.data.emails.join(', ')}');
    if (widget.data.phones.isNotEmpty) buffer.writeln('Phone: ${widget.data.phones.join(', ')}');
    if (widget.data.websites.isNotEmpty) buffer.writeln('Website: ${widget.data.websites.join(', ')}');
    if (widget.data.address != null) buffer.writeln('Address: ${widget.data.address}');
    
    buffer.writeln('\n--- Raw Text ---');
    buffer.writeln(widget.data.rawText);
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
