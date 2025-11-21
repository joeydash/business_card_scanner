import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/business_card_data.dart';
import '../../../services/card_storage_service.dart';

class StructuredResultScreen extends StatefulWidget {
  final BusinessCardData data;
  final int? cardIndex;

  const StructuredResultScreen({
    super.key,
    required this.data,
    this.cardIndex,
  });

  @override
  State<StructuredResultScreen> createState() => _StructuredResultScreenState();
}

class _StructuredResultScreenState extends State<StructuredResultScreen> {
  final CardStorageService _storageService = CardStorageService();
  bool _isSaving = false;
  bool _isEditMode = false;
  
  // Text editing controllers
  late TextEditingController _personNameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _pronounsController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _linkedInController;
  late TextEditingController _twitterController;
  late TextEditingController _companyNameController;
  late TextEditingController _departmentController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late TextEditingController _faxController;
  late TextEditingController _taglineController;

  late BusinessCardData _editedData;

  @override
  void initState() {
    super.initState();
    _editedData = widget.data;
    _initializeControllers();
  }

  void _initializeControllers() {
    _personNameController = TextEditingController(text: _editedData.personName ?? '');
    _jobTitleController = TextEditingController(text: _editedData.jobTitle ?? '');
    _pronounsController = TextEditingController(text: _editedData.pronouns ?? '');
    _emailController = TextEditingController(text: _editedData.emails.join(', '));
    _phoneController = TextEditingController(text: _editedData.phones.join(', '));
    _websiteController = TextEditingController(text: _editedData.websites.join(', '));
    _linkedInController = TextEditingController(text: _editedData.linkedIn ?? '');
    _twitterController = TextEditingController(text: _editedData.twitter ?? '');
    _companyNameController = TextEditingController(text: _editedData.companyName ?? '');
    _departmentController = TextEditingController(text: _editedData.department ?? '');
    _addressController = TextEditingController(text: _editedData.address ?? '');
    _cityController = TextEditingController(text: _editedData.city ?? '');
    _stateController = TextEditingController(text: _editedData.state ?? '');
    _postalCodeController = TextEditingController(text: _editedData.postalCode ?? '');
    _countryController = TextEditingController(text: _editedData.country ?? '');
    _faxController = TextEditingController(text: _editedData.fax ?? '');
    _taglineController = TextEditingController(text: _editedData.tagline ?? '');
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _jobTitleController.dispose();
    _pronounsController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _linkedInController.dispose();
    _twitterController.dispose();
    _companyNameController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _faxController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode) {
        // Exiting edit mode - update the data
        _editedData = BusinessCardData(
          personName: _personNameController.text.isEmpty ? null : _personNameController.text,
          jobTitle: _jobTitleController.text.isEmpty ? null : _jobTitleController.text,
          pronouns: _pronounsController.text.isEmpty ? null : _pronounsController.text,
          emails: _emailController.text.isEmpty ? [] : _emailController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          phones: _phoneController.text.isEmpty ? [] : _phoneController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          websites: _websiteController.text.isEmpty ? [] : _websiteController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          linkedIn: _linkedInController.text.isEmpty ? null : _linkedInController.text,
          twitter: _twitterController.text.isEmpty ? null : _twitterController.text,
          companyName: _companyNameController.text.isEmpty ? null : _companyNameController.text,
          department: _departmentController.text.isEmpty ? null : _departmentController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          city: _cityController.text.isEmpty ? null : _cityController.text,
          state: _stateController.text.isEmpty ? null : _stateController.text,
          postalCode: _postalCodeController.text.isEmpty ? null : _postalCodeController.text,
          country: _countryController.text.isEmpty ? null : _countryController.text,
          fax: _faxController.text.isEmpty ? null : _faxController.text,
          tagline: _taglineController.text.isEmpty ? null : _taglineController.text,
          rawText: _editedData.rawText,
        );
      }
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveCard() async {
    setState(() => _isSaving = true);
    try {
      if (widget.cardIndex != null) {
        // Update existing card
        await _storageService.updateCard(widget.cardIndex!, _editedData);
      } else {
        // Save new card
        await _storageService.saveCard(_editedData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved successfully!')),
        );
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
        title: Text(_isEditMode ? 'Edit Business Card' : 'Business Card Details'),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: 'Copy All Data',
              onPressed: () => _copyAllData(context),
            ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            tooltip: _isEditMode ? 'Done Editing' : 'Edit',
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Contact Information'),
            _buildParsedFields(),
            
            const SizedBox(height: 16),
            
            if (!_isEditMode) ...[
              _buildSectionHeader('Original OCR Text'),
              _buildRawTextCard(),
            ],
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _isEditMode
          ? SafeArea(
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
            )
          : null,
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
          _buildField('👤 Person Name', _personNameController, _editedData.personName),
          _buildField('💼 Job Title', _jobTitleController, _editedData.jobTitle),
          _buildField('🏷️ Pronouns', _pronounsController, _editedData.pronouns),
          _buildField('📧 Email', _emailController, _editedData.emails.join(', ')),
          _buildField('📱 Phone', _phoneController, _editedData.phones.join(', ')),
          _buildField('🌐 Website', _websiteController, _editedData.websites.join(', ')),
          _buildField('💼 LinkedIn', _linkedInController, _editedData.linkedIn),
          _buildField('🐦 Twitter', _twitterController, _editedData.twitter),
          _buildField('🏢 Company Name', _companyNameController, _editedData.companyName),
          _buildField('🏛️ Department', _departmentController, _editedData.department),
          _buildField('📍 Address', _addressController, _editedData.address),
          _buildField('🏙️ City', _cityController, _editedData.city),
          _buildField('🗺️ State', _stateController, _editedData.state),
          _buildField('📮 Postal Code', _postalCodeController, _editedData.postalCode),
          _buildField('🌍 Country', _countryController, _editedData.country),
          _buildField('📠 Fax', _faxController, _editedData.fax),
          _buildField('💬 Tagline', _taglineController, _editedData.tagline),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String? value) {
    if (!_isEditMode && (value == null || value.isEmpty)) {
      return _buildNullField(label);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: _isEditMode ? 3 : 2,
      color: _isEditMode ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (_isEditMode)
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(value ?? '', label),
                  ),
                ],
              ),
          ],
        ),
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
                  onPressed: () => _copyToClipboard(_editedData.rawText, 'Raw Text'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              _editedData.rawText.isEmpty ? 'No text detected' : _editedData.rawText,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _copyAllData(BuildContext context) {
    final buffer = StringBuffer();
    
    if (_editedData.personName != null) buffer.writeln('Name: ${_editedData.personName}');
    if (_editedData.jobTitle != null) buffer.writeln('Title: ${_editedData.jobTitle}');
    if (_editedData.companyName != null) buffer.writeln('Company: ${_editedData.companyName}');
    if (_editedData.emails.isNotEmpty) buffer.writeln('Email: ${_editedData.emails.join(', ')}');
    if (_editedData.phones.isNotEmpty) buffer.writeln('Phone: ${_editedData.phones.join(', ')}');
    if (_editedData.websites.isNotEmpty) buffer.writeln('Website: ${_editedData.websites.join(', ')}');
    if (_editedData.address != null) buffer.writeln('Address: ${_editedData.address}');
    
    buffer.writeln('\n--- Raw Text ---');
    buffer.writeln(_editedData.rawText);
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
