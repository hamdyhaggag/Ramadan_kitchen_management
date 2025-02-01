import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import '../../../../../cloudinary_config.dart';
import '../../../../manage_cases/donation_section.dart';

class EditableDonationSection extends StatefulWidget {
  final Map<String, dynamic> donationData;
  const EditableDonationSection({super.key, required this.donationData});

  @override
  State<EditableDonationSection> createState() =>
      _EditableDonationSectionState();
}

class _EditableDonationSectionState extends State<EditableDonationSection> {
  late final TextEditingController _mealTitleController;
  late final TextEditingController _mealDescriptionController;
  late List<ContactPerson> _contacts;
  File? _pickedImage;
  bool _isUploading = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _mealTitleController =
        TextEditingController(text: widget.donationData['mealTitle'] ?? '');
    _mealDescriptionController = TextEditingController(
        text: widget.donationData['mealDescription'] ?? '');
    _existingImageUrl = widget.donationData['mealImageUrl'];
    _contacts = (widget.donationData['contacts'] as List<dynamic>)
        .map<ContactPerson>((e) {
      if (e is ContactPerson) return e;
      if (e is Map<String, dynamic>) return ContactPerson.fromMap(e);
      throw Exception('Invalid contact type: ${e.runtimeType}');
    }).toList();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final File file = File(pickedFile.path);
    if (await file.length() > 10 * 1024 * 1024) {
      _showSnackbar('حجم الصورة لا يجب أن يتجاوز 10 ميجابايت');
      return;
    }

    setState(() {
      _pickedImage = file;
      _existingImageUrl = null;
    });
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar('يجب تسجيل الدخول أولاً');
      return;
    }
    if (_mealTitleController.text.trim().isEmpty) {
      _showSnackbar('يرجى إدخال عنوان الوجبة');
      return;
    }

    setState(() => _isUploading = true);
    try {
      String? imageUrl = _existingImageUrl;

      if (_pickedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_pickedImage!);
      }

      await FirebaseFirestore.instance.collection('donations').doc().set({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'mealImageUrl': imageUrl,
        'mealTitle': _mealTitleController.text.trim(),
        'mealDescription': _mealDescriptionController.text.trim(),
        'contacts': _contacts.map((c) => c.toMap()).toList(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      _showSnackbar('تم حفظ التغييرات بنجاح');
    } catch (e) {
      _showSnackbar('حدث خطأ: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String> _uploadImageToCloudinary(File image) async {
    final String fileName =
        'meal_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final String tempPath = '${image.path}_compressed.jpg';

    final XFile? compressedResult =
        await FlutterImageCompress.compressAndGetFile(
      image.path,
      tempPath,
      quality: 80,
      minWidth: 1024,
      minHeight: 1024,
    );

    final File finalFile =
        compressedResult != null ? File(compressedResult.path) : image;

    final cloudinary = CloudinaryPublic(
      cloudinaryCloudName,
      cloudinaryUploadPreset,
    );
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(finalFile.path,
          resourceType: CloudinaryResourceType.Image,
          publicId: fileName,
          folder: 'meal_images'),
    );
    return response.secureUrl;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('معلومات الوجبة الأساسية', Icons.fastfood),
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildTitleField(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 30),
            _buildContactsSection(),
            const SizedBox(height: 30),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _pickedImage != null
            ? _buildImagePreview()
            : _existingImageUrl != null
                ? _buildNetworkImage()
                : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_pickedImage!, fit: BoxFit.cover),
        ),
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildNetworkImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _existingImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: Center(
                  child: Icon(Icons.broken_image,
                      size: 40, color: Colors.grey[400])),
            ),
          ),
        ),
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: IconButton(
        icon: Icon(Icons.delete, color: Colors.red[700]),
        onPressed: () => setState(() {
          _pickedImage = null;
          _existingImageUrl = null;
        }),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text('انقر لإضافة صورة الوجبة',
            style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _mealTitleController,
      decoration: InputDecoration(
        labelText: 'عنوان الوجبة',
        hintText: 'أدخل عنواناً جذاباً للوجبة',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _mealDescriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'وصف الوجبة',
        hintText: 'صف مكونات الوجبة وأي تفاصيل مهمة',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildContactsSection() {
    return Column(
      children: [
        _buildSectionHeader('جهات الاتصال', Icons.contacts),
        ..._contacts.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContactEditor(
                contact: entry.value,
                onChanged: (newContact) =>
                    setState(() => _contacts[entry.key] = newContact),
                onRemove: () => setState(() => _contacts.removeAt(entry.key)),
              ),
            )),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('إضافة جهة اتصال جديدة'),
          onPressed: () => setState(() => _contacts.add(ContactPerson(
              name: '', phoneNumber: '', role: '', bankAccount: ''))),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GeneralButton(
        icon: _isUploading
            ? SizedBox(
                width: 24,
                height: 24,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.save_alt),
        onPressed: _isUploading ? null : _saveChanges,
        text: _isUploading ? 'جاري الحفظ...' : 'حفظ التغييرات',
        backgroundColor: AppColors.primaryColor,
        textColor: AppColors.whiteColor);
  }
}

class ContactEditor extends StatefulWidget {
  final ContactPerson contact;
  final Function(ContactPerson) onChanged;
  final VoidCallback onRemove;

  const ContactEditor(
      {super.key,
      required this.contact,
      required this.onChanged,
      required this.onRemove});

  @override
  State<ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<ContactEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;
  late final TextEditingController _bankController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phoneNumber);
    _roleController = TextEditingController(text: widget.contact.role);
    _bankController = TextEditingController(text: widget.contact.bankAccount);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildContactField(_nameController, 'الاسم الكامل', Icons.person),
            const SizedBox(height: 12),
            _buildContactField(_phoneController, 'رقم الهاتف', Icons.phone,
                TextInputType.phone),
            const SizedBox(height: 12),
            _buildContactField(
                _roleController, 'الدور/المسمى الوظيفي', Icons.work_outline),
            const SizedBox(height: 12),
            _buildContactField(
                _bankController, 'الحساب البنكي', Icons.account_balance),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف جهة الاتصال'),
                onPressed: widget.onRemove,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactField(
      TextEditingController controller, String label, IconData icon,
      [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => widget.onChanged(ContactPerson(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        role: _roleController.text,
        bankAccount: _bankController.text,
      )),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
