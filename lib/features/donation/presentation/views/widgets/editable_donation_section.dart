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
  final String documentId;

  const EditableDonationSection({
    super.key,
    required this.donationData,
    required this.documentId,
  });

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
    _initializeControllers();
  }

  void _initializeControllers() {
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
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
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
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _showSnackbar('يجب تسجيل الدخول أولاً');
    if (_mealTitleController.text.trim().isEmpty)
      return _showSnackbar('يرجى إدخال عنوان الوجبة');

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_pickedImage!);
        if (imageUrl == null) throw Exception('فشل تحميل الصورة');
      }

      final donationData = _prepareDonationData(user, imageUrl);

      if (widget.documentId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(widget.documentId)
            .update(donationData);
      } else {
        donationData['userId'] = user.uid;
        donationData['created_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('donations')
            .add(donationData);
      }

      _showSnackbar('تم حفظ التغييرات بنجاح');
      _safeNavigateBack();
    } on FirebaseException catch (e) {
      _showSnackbar('خطأ في قاعدة البيانات: ${e.code}');
    } catch (e) {
      _showSnackbar('حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Map<String, dynamic> _prepareDonationData(User user, String? imageUrl) {
    return {
      'mealImageUrl': imageUrl,
      'mealTitle': _mealTitleController.text.trim(),
      'mealDescription': _mealDescriptionController.text.trim(),
      'contacts': _contacts.map((c) => c.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      final fileName =
          'meal_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final tempPath = '${image.path}_compressed.jpg';

      final compressedResult = await FlutterImageCompress.compressAndGetFile(
        image.path,
        tempPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );

      final finalFile =
          compressedResult != null ? File(compressedResult.path) : image;

      final cloudinary =
          CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          finalFile.path,
          resourceType: CloudinaryResourceType.Image,
          publicId: fileName,
          folder: 'meal_images',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      _showSnackbar('فشل رفع الصورة');
      return null;
    }
  }

  void _safeNavigateBack() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
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
            _buildSectionHeader(
                'معلومات الوجبة الأساسية', Icons.fastfood_rounded),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 24),
            _buildTitleField(),
            const SizedBox(height: 24),
            _buildDescriptionField(),
            const SizedBox(height: 32),
            _buildContactsSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 28),
            ),
            const SizedBox(width: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withAlpha(76),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 4)
          ],
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.5,
            style: _pickedImage == null && _existingImageUrl == null
                ? BorderStyle.solid
                : BorderStyle.none,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (_pickedImage != null) _buildImagePreview(),
              if (_existingImageUrl != null) _buildNetworkImage(),
              if (_pickedImage == null && _existingImageUrl == null)
                _buildImagePlaceholder(),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('إضافة صورة', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              if (_pickedImage != null || _existingImageUrl != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_forever_rounded,
                          color: Colors.red[700], size: 24),
                    ),
                    onPressed: () => setState(() {
                      _pickedImage = null;
                      _existingImageUrl = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _mealTitleController,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'عنوان الوجبة',
        hintText: 'أدخل عنواناً جذاباً للوجبة',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          child: Icon(Icons.title_rounded, color: Colors.grey[600]),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _mealDescriptionController,
      maxLines: 4,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'وصف الوجبة',
        hintText: 'صف مكونات الوجبة وأي تفاصيل مهمة',
        alignLabelWithHint: true,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          child: Icon(Icons.description_rounded, color: Colors.grey[600]),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildContactsSection() {
    return Column(
      children: [
        _buildSectionHeader('جهات الاتصال', Icons.contacts_rounded),
        const SizedBox(height: 16),
        ..._contacts.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ContactEditor(
                contact: entry.value,
                onChanged: (newContact) =>
                    setState(() => _contacts[entry.key] = newContact),
                onRemove: () => setState(() => _contacts.removeAt(entry.key)),
              ),
            )),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            label: const Text('إضافة جهة اتصال جديدة',
                style: TextStyle(fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[50],
              foregroundColor: AppColors.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: AppColors.primaryColor.withAlpha(76), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => setState(() => _contacts.add(ContactPerson(
                name: '', phoneNumber: '', role: '', bankAccount: ''))),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GeneralButton(
      icon: _isUploading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 3),
            )
          : const Icon(Icons.save_rounded, size: 24),
      onPressed: _isUploading ? null : _saveChanges,
      text: _isUploading ? 'جاري الحفظ...' : 'حفظ التغييرات',
      backgroundColor: AppColors.primaryColor,
      textColor: Colors.white,
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(_pickedImage!, fit: BoxFit.cover),
    );
  }

  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        _existingImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: Center(
              child:
                  Icon(Icons.broken_image, size: 40, color: Colors.grey[400])),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Center(
            child: Text('انقر لإضافة صورة الوجبة',
                style: TextStyle(color: Colors.grey[600]))),
      ],
    );
  }
}

class ContactEditor extends StatefulWidget {
  final ContactPerson contact;
  final Function(ContactPerson) onChanged;
  final VoidCallback onRemove;

  const ContactEditor({
    super.key,
    required this.contact,
    required this.onChanged,
    required this.onRemove,
  });

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 4)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.contact_page_rounded,
                    color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                    'جهة الاتصال ${widget.contact.name.isNotEmpty ? widget.contact.name : "الجديدة"}',
                    style: TextStyle(
                        color: Colors.grey[700], fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey[600], size: 22),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const Divider(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3,
              children: [
                _buildContactField(_nameController, 'الاسم الكامل',
                    Icons.person_outline_rounded),
                _buildContactField(_phoneController, 'رقم الهاتف',
                    Icons.phone_iphone_rounded, TextInputType.phone),
                _buildContactField(
                    _roleController, 'الدور', Icons.work_outline_rounded),
                _buildContactField(_bankController, 'الحساب البنكي',
                    Icons.account_balance_wallet_rounded),
              ],
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
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primaryColor, width: 1.2),
        ),
      ),
    );
  }
}
