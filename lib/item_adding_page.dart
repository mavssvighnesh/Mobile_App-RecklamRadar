import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recklamradar/services/firestore_service.dart';
import 'package:recklamradar/utils/message_utils.dart';
import 'package:recklamradar/providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:recklamradar/utils/size_config.dart';

class ItemAddingPage extends StatefulWidget {
  final String storeId;
  final String storeName;
  final VoidCallback onItemAdded;

  const ItemAddingPage({
    super.key, 
    required this.storeId,
    required this.storeName,
    required this.onItemAdded,
  });

  @override
  _ItemAddingPageState createState() => _ItemAddingPageState();
}

class _ItemAddingPageState extends State<ItemAddingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _memberPriceController = TextEditingController();
  
  String? selectedCategory;
  String? selectedUnit;
  DateTimeRange? dateRange;
  File? _imageFile;
  bool isLoading = false;

  final List<String> categories = ["Groceries", "Electronics", "Clothing", "Home", "Other"];
  final List<String> units = ["KG", "ST", "L", "Pack"];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _memberPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 70,
                        );
                        if (image != null) {
                          setState(() => _imageFile = File(image.path));
                        }
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 70,
                        );
                        if (image != null) {
                          setState(() => _imageFile = File(image.path));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      showMessage(context, 'Error picking image: $e', false);
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('stores/${widget.storeId}/items')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      showMessage(context, 'Error uploading image: $e', false);
      return null;
    }
  }

  Future<void> _checkExistingItem() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('items')
          .where('name', isEqualTo: _nameController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Item exists, update it
        final docId = querySnapshot.docs.first.id;
        await _updateItem(docId);
      } else {
        // Item doesn't exist, create new
        await _createItem();
      }
    } catch (e) {
      showMessage(context, 'Error checking item: $e', false);
    }
  }

  Future<void> _updateItem(String docId) async {
    try {
      final imageUrl = _imageFile != null ? await _uploadImage() : null;
      
      final data = {
        'name': _nameController.text.trim(),
        'category': selectedCategory,
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'salePrice': double.parse(_memberPriceController.text),
        'unit': selectedUnit,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('items')
          .doc(docId)
          .update(data);

      if (mounted) {
        showMessage(context, 'Item updated successfully!', true);
        widget.onItemAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      showMessage(context, 'Error updating item: $e', false);
    }
  }

  Future<void> _createItem() async {
    try {
      final imageUrl = await _uploadImage();
      if (imageUrl == null) {
        showMessage(context, 'Please upload an image', false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('items')
          .add({
        'name': _nameController.text.trim(),
        'category': selectedCategory,
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'salePrice': _memberPriceController.text.isEmpty 
            ? null 
            : double.parse(_memberPriceController.text),
        'unit': selectedUnit,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'inStock': true,
      });

      if (mounted) {
        showMessage(context, 'Item added successfully!', true);
        widget.onItemAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      showMessage(context, 'Error creating item: $e', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Item to ${widget.storeName}',
          style: TextStyle(fontSize: SizeConfig.fontSize),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ThemeProvider.cardGradient,
          ),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: ThemeProvider.subtleGradient,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(SizeConfig.blockSizeHorizontal * 4),
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: SizeConfig.getProportionateScreenHeight(200),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 3),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 3),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: SizeConfig.blockSizeHorizontal * 12,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add Item Image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: SizeConfig.fontSize,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 2),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Item Name',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter item name' : null,
              ),

              // Description Field
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
              ),

              // Price Field
              _buildTextField(
                controller: _priceController,
                label: 'Regular Price (SEK)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter price';
                  if (double.tryParse(value!) == null) return 'Please enter valid price';
                  return null;
                },
              ),

              // Member Price Field
              _buildTextField(
                controller: _memberPriceController,
                label: 'Member Price (SEK) (Optional)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return null;
                  if (double.tryParse(value!) == null) return 'Please enter valid price';
                  return null;
                },
              ),

              // Category Dropdown
              Container(
                margin: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical * 2),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 3),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  hint: Text('Select Category'),
                  isExpanded: true,
                  items: categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value),
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
              ),

              // Unit Dropdown
              Container(
                margin: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical * 2),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 3),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedUnit,
                  hint: Text('Select Unit'),
                  isExpanded: true,
                  items: units.map((String unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedUnit = value),
                  validator: (value) => value == null ? 'Please select a unit' : null,
                ),
              ),

              // Submit Button
              Container(
                margin: EdgeInsets.symmetric(vertical: SizeConfig.blockSizeVertical * 2),
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      await _checkExistingItem();
                      setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 3),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Add Item',
                          style: TextStyle(
                            fontSize: SizeConfig.fontSize,
                            fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.blockSizeVertical * 2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(fontSize: SizeConfig.fontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: SizeConfig.fontSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SizeConfig.blockSizeHorizontal * 3),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.blockSizeHorizontal * 4,
            vertical: SizeConfig.blockSizeVertical * 2,
          ),
        ),
        validator: validator,
      ),
    );
  }
}