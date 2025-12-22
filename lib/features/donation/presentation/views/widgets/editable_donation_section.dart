import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

import 'package:iconsax/iconsax.dart';
import '../../../../../cloudinary_config.dart';
import '../../cubit/donation_cubit.dart';
import 'contact_person.dart';

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
  late final TextEditingController _numberOfIndividualsController;
  late List<ContactPerson> _contacts;
  File? _pickedImage;
  bool _isUploading = false;
  String? _existingImageUrl;
  final List<File> _pickedCarouselImages = [];
  List<String> _existingCarouselImages = [];
  DateTime _selectedDate = DateTime.now(); // Default to today
  List<String> _suggestedIngredients = [];
  String _selectedIngredientCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSuggestedIngredients();
    // Removed auto-detection and auto-fetch from initState to prevent
    // overriding the data passed from the parent widget.
  }

  void _initializeControllers() {
    _mealTitleController =
        TextEditingController(text: widget.donationData['mealTitle'] ?? '');
    _mealDescriptionController = TextEditingController(
        text: widget.donationData['mealDescription'] ?? '');
    _numberOfIndividualsController = TextEditingController(
        text: widget.donationData['numberOfIndividuals']?.toString() ?? '0');
    _existingImageUrl = widget.donationData['mealImageUrl'];
    _existingCarouselImages = widget.donationData['carouselImages'] != null
        ? List<String>.from(widget.donationData['carouselImages'])
        : [];
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

  Future<void> _pickCarouselImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isEmpty) return;
    for (var pickedFile in pickedFiles) {
      final file = File(pickedFile.path);
      if (await file.length() > 10 * 1024 * 1024) {
        _showSnackbar('أحد الصور تجاوز الحد المسموح');
        continue;
      }
      if ((_pickedCarouselImages.length + _existingCarouselImages.length) < 5) {
        setState(() {
          _pickedCarouselImages.add(file);
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _showSnackbar('يجب تسجيل الدخول أولاً');
    if (_mealTitleController.text.trim().isEmpty) {
      return _showSnackbar('يرجى إدخال عنوان الوجبة');
    }
    setState(() => _isUploading = true);
    try {
      String? imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_pickedImage!);
      }
      List<String> carouselImageUrls = List.from(_existingCarouselImages);
      for (var file in _pickedCarouselImages) {
        final url = await _uploadImageToCloudinary(file);
        if (url != null) {
          carouselImageUrls.add(url);
        }
      }
      final donationData = {
        'mealImageUrl': imageUrl,
        'mealTitle': _mealTitleController.text.trim(),
        'mealDescription': _mealDescriptionController.text.trim(),
        'numberOfIndividuals':
            int.tryParse(_numberOfIndividualsController.text.trim()) ?? 0,
        'carouselImages': carouselImageUrls,
        'contacts': _contacts.map((c) => c.toMap()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Use selected date for search/save
      final startOfDay =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('created_at', isGreaterThanOrEqualTo: startOfDay)
          .where('created_at', isLessThanOrEqualTo: endOfDay)
          .get();

      DocumentReference docRef;
      if (querySnapshot.docs.isNotEmpty) {
        docRef = querySnapshot.docs.first.reference;
        await docRef.update(donationData);
        if (querySnapshot.docs.length > 1) {
          for (int i = 1; i < querySnapshot.docs.length; i++) {
            await querySnapshot.docs[i].reference.delete();
          }
        }
      } else {
        donationData['created_at'] = Timestamp.fromDate(startOfDay); // Fix date
        docRef = await FirebaseFirestore.instance
            .collection('donations')
            .add(donationData);
      }
      final updatedDoc = await docRef.get();
      if (updatedDoc.exists) {
        final data = updatedDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _mealTitleController.text = data['mealTitle'] ?? '';
            _mealDescriptionController.text = data['mealDescription'] ?? '';
            _numberOfIndividualsController.text =
                data['numberOfIndividuals']?.toString() ?? '0';
            _existingImageUrl = data['mealImageUrl'];
            _existingCarouselImages = data['carouselImages'] != null
                ? List<String>.from(data['carouselImages'])
                : [];
            _pickedCarouselImages.clear();
            _contacts =
                (data['contacts'] as List<dynamic>).map<ContactPerson>((e) {
              if (e is ContactPerson) return e;
              if (e is Map<String, dynamic>) return ContactPerson.fromMap(e);
              throw Exception('Invalid contact type: ${e.runtimeType}');
            }).toList();
          });
        }
      }
      if (mounted) {
        context.read<DonationCubit>().getDonations();
        _showSnackbar('تم حفظ التغييرات بنجاح');
      }
    } catch (e) {
      _showSnackbar('حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      final fileName =
          'meal_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final tempPath = '${image.path}_compressed.jpg';
      final compressedResult = await FlutterImageCompress.compressAndGetFile(
          image.path, tempPath,
          quality: 80, minWidth: 1024, minHeight: 1024);
      final finalFile =
          compressedResult != null ? File(compressedResult.path) : image;
      final cloudinary =
          CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(finalFile.path,
            resourceType: CloudinaryResourceType.Image,
            publicId: fileName,
            folder: 'meal_images'),
      );
      return response.secureUrl;
    } catch (e) {
      _showSnackbar('فشل رفع الصورة');
      return null;
    }
  }

  void safeNavigateBack() {
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Selector
          _buildDateSelector(),
          const SizedBox(height: 24),

          // Image Picker Section (The Meal Image)
          _buildSectionHeader('صورة وجبة اليوم (تظهر للتبرع)', Iconsax.image),
          const SizedBox(height: 12),
          _buildImagePicker(),
          const SizedBox(height: 24),

          // Carousel Section (The Promo Images)
          _buildSectionHeader(
              'صور الشريط الإعلاني (Carousel)', Iconsax.gallery),
          const SizedBox(height: 12),
          _buildCarouselImagesSection(),
          const SizedBox(height: 32),

          // Basic Info Section
          _buildSectionHeader('معلومات الوجبة', Iconsax.note_text),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _mealTitleController,
            label: 'عنوان الوجبة',
            hint: 'مثال: وجبة إفطار صائم',
            icon: Iconsax.clipboard_text,
          ),
          const SizedBox(height: 16),
          _buildIngredientField(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _numberOfIndividualsController,
            label: 'العدد المستهدف (الأفراد)',
            hint: '100',
            icon: Iconsax.people,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 32),

          // Payment Methods Section
          _buildSectionHeader('معلومات الدفع والتبرع', Iconsax.card),
          const SizedBox(height: 16),
          ..._contacts.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ContactEditor(
                  contact: entry.value,
                  index: entry.key,
                  onChanged: (newContact) =>
                      setState(() => _contacts[entry.key] = newContact),
                  onRemove: () => setState(() => _contacts.removeAt(entry.key)),
                ),
              )),

          InkWell(
            onTap: () => setState(() => _contacts.add(ContactPerson(
                name: 'طريقة دفع جديدة',
                phoneNumber: '',
                role: '',
                bankAccount: '',
                additionalPaymentInfo: ''))),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primaryColor.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.add_circle, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'إضافة طريقة دفع جديدة',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blackColor,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _pickedImage != null || _existingImageUrl != null;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: hasImage
              ? null
              : Border.all(color: Colors.grey[300]!, style: BorderStyle.none),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_pickedImage != null)
                Image.file(_pickedImage!, fit: BoxFit.cover)
              else if (_existingImageUrl != null)
                Image.network(
                  _existingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              if (hasImage)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.camera, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('تغيير الصورة',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: const Icon(Iconsax.image,
                size: 40, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            'أضف صورة الوجبة الفعلية من المطبخ',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Iconsax.gallery, size: 18, color: Colors.grey),
            SizedBox(width: 8),
            Text('إعلانات الشريط العلوي (اختياري)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _existingCarouselImages.length +
                _pickedCarouselImages.length +
                1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < _existingCarouselImages.length) {
                return _buildCarouselThumbnail(
                  imageProvider: NetworkImage(_existingCarouselImages[index]),
                  onRemove: () =>
                      setState(() => _existingCarouselImages.removeAt(index)),
                );
              }
              int newIndex = index - _existingCarouselImages.length;
              if (newIndex < _pickedCarouselImages.length) {
                return _buildCarouselThumbnail(
                  imageProvider: FileImage(_pickedCarouselImages[newIndex]),
                  onRemove: () =>
                      setState(() => _pickedCarouselImages.removeAt(newIndex)),
                );
              }
              return InkWell(
                onTap: _pickCarouselImages,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.none), // Dashed border alternative
                  ),
                  child: const Center(
                    child: Icon(Iconsax.add,
                        color: AppColors.primaryColor, size: 32),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselThumbnail(
      {required ImageProvider imageProvider, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image(
              image: imageProvider, width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
            filled: true,
            fillColor: Colors.grey[50],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          elevation: 4,
          shadowColor: AppColors.primaryColor.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isUploading ? null : _saveChanges,
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.tick_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('حفظ التغييرات',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
      ),
    );
  }

  Future<void> _fetchDataForSelectedDate() async {
    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('created_at', isGreaterThanOrEqualTo: startOfDay)
          .where('created_at', isLessThanOrEqualTo: endOfDay)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _mealTitleController.text = data['mealTitle'] ?? '';
          _mealDescriptionController.text = data['mealDescription'] ?? '';
          _numberOfIndividualsController.text =
              data['numberOfIndividuals']?.toString() ?? '0';
          _existingImageUrl = data['mealImageUrl'];
          _existingCarouselImages = data['carouselImages'] != null
              ? List<String>.from(data['carouselImages'])
              : [];
          _pickedImage = null;
          _pickedCarouselImages.clear();
        });
      } else {
        // If no data for this specific day, reset fields (but keep title if needed or clear)
        setState(() {
          _mealTitleController.clear();
          _mealDescriptionController.clear();
          _numberOfIndividualsController.text = '0';
          _existingImageUrl = null;
          _existingCarouselImages = [];
          _pickedImage = null;
          _pickedCarouselImages.clear();
        });
      }
    } catch (e) {
      debugPrint('Error fetching data for selected date: $e');
    }
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('توقيت الوجبة', Iconsax.calendar),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDateOption(
                'أمس', DateTime.now().subtract(const Duration(days: 1))),
            const SizedBox(width: 8),
            _buildDateOption('اليوم', DateTime.now()),
            const SizedBox(width: 8),
            _buildDateOption(
                'غداً', DateTime.now().add(const Duration(days: 1))),
          ],
        ),
      ],
    );
  }

  Widget _buildDateOption(String label, DateTime date) {
    bool isSelected = _selectedDate.day == date.day &&
        _selectedDate.month == date.month &&
        _selectedDate.year == date.year;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
          _fetchDataForSelectedDate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadSuggestedIngredients() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .orderBy('created_at', descending: true)
          .limit(50) // Look at last 50 meals
          .get();

      final Set<String> uniqueIngredients = {};
      for (var doc in snapshot.docs) {
        final desc = doc.data()['mealDescription'] as String?;
        if (desc != null && desc.isNotEmpty) {
          final items = desc.split(RegExp(r'\+|\,')).map((e) => e.trim());
          for (var item in items) {
            if (item.isNotEmpty) uniqueIngredients.add(item);
          }
        }
      }

      if (mounted) {
        setState(() {
          _suggestedIngredients = uniqueIngredients.toList()..sort();
        });
      }
    } catch (e) {
      debugPrint('Error loading suggested ingredients: $e');
    }
  }

  void _appendIngredient(String ingredient) {
    String currentText = _mealDescriptionController.text.trim();
    if (currentText.isEmpty) {
      _mealDescriptionController.text = ingredient;
    } else {
      // Check if it's already there to avoid duplicates
      final items = currentText.split(RegExp(r'\+|\,')).map((e) => e.trim());
      if (!items.contains(ingredient)) {
        _mealDescriptionController.text = '$currentText + $ingredient';
      }
    }
  }

  List<String> _getFilteredIngredients() {
    if (_selectedIngredientCategory == 'الكل') return _suggestedIngredients;

    final Map<String, List<String>> categories = {
      'بروتين': [
        'لحم',
        'دجاج',
        'فراخ',
        'كفتة',
        'سمك',
        'بط',
        'أرنب',
        'بيض',
        'كبدة'
      ],
      'نشويات': [
        'أرز',
        'مكرونة',
        'بطاطس',
        'لسان',
        'شعرية',
        'خبز',
        'عيش',
        'محشي',
        'رقاق'
      ],
      'خضروات': [
        'فاصوليا',
        'بسلة',
        'خضار',
        'سلطة',
        'ملوخية',
        'شوربة',
        'لوبيا',
        'بامية',
        'سبانخ',
        'عدس'
      ],
      'مقبلات': ['مخلل', 'طرشي', 'تمر', 'بلح', 'زيتون'],
      'مشروبات': [
        'عصير',
        'سوبيا',
        'عرقسوس',
        'تمر هندي',
        'قمر الدين',
        'مانجو',
        'فراولة',
        'خشاف'
      ],
      'حلويات': ['كنافة', 'بسبوسة', 'قطايف', 'أرز بلبن', 'مهلبية'],
    };

    final keywords = categories[_selectedIngredientCategory] ?? [];
    return _suggestedIngredients.where((ingredient) {
      return keywords.any((k) => ingredient.contains(k));
    }).toList();
  }

  Widget _buildIngredientField() {
    final filtered = _getFilteredIngredients();
    final categories = [
      'الكل',
      'بروتين',
      'نشويات',
      'خضروات',
      'مقبلات',
      'مشروبات',
      'حلويات'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('مكونات الوجبة (استخدم علامة + للفصل)',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _mealDescriptionController,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'أرز + خضار + لحم...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon:
                const Icon(Iconsax.menu_board, color: Colors.grey, size: 22),
            filled: true,
            fillColor: Colors.grey[50],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
          ),
        ),
        if (_suggestedIngredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Category Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                bool isSelected = _selectedIngredientCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => _selectedIngredientCategory = cat),
                    selectedColor:
                        AppColors.primaryColor.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryColor : Colors.grey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey[200]!,
                    ),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Grouped Chips
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('لا توجد مكونات في هذا القسم حالياً',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filtered.map((item) {
                return InkWell(
                  onTap: () => _appendIngredient(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[100]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline,
                            size: 14, color: AppColors.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
        const SizedBox(height: 16),
        const Text(
          '💡 سيتم عرض كل صنف في بطاقة منفصلة للمستخدم.',
          style: TextStyle(
              fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class ContactEditor extends StatefulWidget {
  final ContactPerson contact;
  final int index;
  final Function(ContactPerson) onChanged;
  final VoidCallback onRemove;
  const ContactEditor({
    super.key,
    required this.contact,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });
  @override
  State<ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<ContactEditor> {
  late final TextEditingController _phoneController;
  late final TextEditingController _bankController;
  late final TextEditingController _additionalPaymentController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.contact.phoneNumber);
    _bankController = TextEditingController(text: widget.contact.bankAccount);
    _additionalPaymentController =
        TextEditingController(text: widget.contact.additionalPaymentInfo ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bankController.dispose();
    _additionalPaymentController.dispose();
    super.dispose();
  }

  void _updateContact() {
    widget.onChanged(ContactPerson(
      name: widget.contact.name,
      phoneNumber: _phoneController.text,
      role: widget.contact.role,
      bankAccount: _bankController.text,
      additionalPaymentInfo: _additionalPaymentController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Iconsax.wallet_2,
                    size: 20, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Text('وسيلة دفع ${widget.index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Iconsax.trash, color: Colors.red, size: 20)),
            ],
          ),
          const Divider(height: 24),
          _buildCompactField(
              _phoneController, 'فودافون كاش', Icons.phone_android),
          const SizedBox(height: 12),
          _buildCompactField(_bankController, 'انستاباي', Icons.credit_card),
          const SizedBox(height: 12),
          _buildCompactField(_additionalPaymentController, 'اتصالات كاش / أخرى',
              Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _buildCompactField(
      TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => _updateContact(),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}
