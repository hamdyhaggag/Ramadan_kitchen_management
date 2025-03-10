import 'dart:convert';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../cloudinary_config.dart';
import '../../../../core/cache/prefs.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/general_button.dart';
import '../../../manage_cases/logic/cases_cubit.dart';

class CaseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;
  const CaseDetailsScreen({super.key, required this.caseData});

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _membersController;
  late TextEditingController _phoneController;
  late List<TextEditingController> _ageControllers;
  File? _pickedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _membersController.addListener(_updateAgeControllers);
    _existingImageUrl = widget.caseData["صورة بطاقة"];
  }

  void _initializeControllers() {
    _nameController =
        TextEditingController(text: widget.caseData["الاسم"] ?? '');
    _membersController = TextEditingController(
        text: (widget.caseData["عدد الأفراد"] ?? 1).toString());
    _phoneController =
        TextEditingController(text: widget.caseData["رقم تليفون"] ?? '');
    int membersCount = int.tryParse(_membersController.text) ?? 1;
    final agesData = widget.caseData["سن كل فرد"] as List<dynamic>?;
    if (agesData != null && agesData.isNotEmpty) {
      _ageControllers = agesData
          .map((age) => TextEditingController(text: age.toString()))
          .toList();
      if (_ageControllers.length < membersCount) {
        int difference = membersCount - _ageControllers.length;
        for (int i = 0; i < difference; i++) {
          _ageControllers.add(TextEditingController(text: ''));
        }
      }
    } else {
      _ageControllers =
          List.generate(membersCount, (_) => TextEditingController(text: ''));
    }
  }

  void _updateAgeControllers() {
    final newCount = int.tryParse(_membersController.text) ?? 1;
    if (newCount <= 0) return;
    setState(() {
      if (newCount > _ageControllers.length) {
        for (int i = _ageControllers.length; i < newCount; i++) {
          _ageControllers.add(TextEditingController(text: ''));
        }
      } else if (newCount < _ageControllers.length) {
        _ageControllers = _ageControllers.sublist(0, newCount);
      }
      if (_ageControllers.isEmpty) {
        _ageControllers.add(TextEditingController(text: ''));
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _pickedImage = File(pickedFile.path);
    });
    bool connected = await _isConnected();
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No internet connection. Image will be uploaded when online.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final imageUrl = await _uploadImageToCloudinary(File(pickedFile.path));
      if (imageUrl != null) {
        setState(() {
          _existingImageUrl = imageUrl;
          _pickedImage = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveChanges() async {
    final updatedData = {
      "الاسم": _nameController.text,
      "عدد الأفراد": int.tryParse(_membersController.text) ?? 1,
      "رقم تليفون": _phoneController.text,
      "صورة بطاقة": _existingImageUrl,
      "سن كل فرد":
          _ageControllers.map((c) => int.tryParse(c.text) ?? 0).toList(),
    };

    bool connected = await _isConnected();
    if (!connected) {
      await Prefs.setString(
        'cached_case_${widget.caseData['id']}',
        jsonEncode(updatedData),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No internet connection. Changes have been cached locally.')),
      );
      return;
    }

    context.read<CasesCubit>().updateCase(widget.caseData['id'], updatedData);
    await Prefs.removeData(key: 'cached_case_${widget.caseData['id']}');
    Navigator.pop(context);
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      const cloudName = cloudinaryCloudName;
      const uploadPreset = cloudinaryUploadPreset;
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        '${image.path}_compressed.jpg',
        quality: 80,
      );
      final cloudinary = CloudinaryPublic(cloudName, uploadPreset);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          compressedFile!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'id_images',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الرفع: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<bool> _isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membersController.dispose();
    _phoneController.dispose();
    for (var c in _ageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الحالة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(_nameController, 'الاسم'),
            const SizedBox(height: 16),
            _buildTextField(
                _membersController, 'عدد الأفراد', TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(
                _phoneController, 'رقم التليفون', TextInputType.phone),
            const SizedBox(height: 24),
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildAgeFieldsSection(),
            const SizedBox(height: 32),
            GeneralButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3))
                  : const Icon(Icons.save_rounded, size: 24),
              onPressed: _isLoading ? null : _saveChanges,
              text: _isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات',
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType? type]) {
    return TextField(
      controller: controller,
      keyboardType: type ?? TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        floatingLabelStyle: TextStyle(color: AppColors.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        suffixIcon: controller == _phoneController
            ? IconButton(
                icon: Icon(Icons.call, color: AppColors.primaryColor),
                onPressed: () async {
                  final phoneNumber = controller.text;
                  if (phoneNumber.isNotEmpty) {
                    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not launch dialer')),
                      );
                    }
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صورة بطاقة الهوية',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                if (_pickedImage != null) _buildImagePreview(),
                if (_pickedImage == null && _existingImageUrl != null)
                  Image.network(
                    _existingImageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                if (_pickedImage == null && _existingImageUrl == null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_a_photo,
                              size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('اضغط لرفع صورة',
                              style: TextStyle(color: Colors.grey)),
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
                        child: Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.red[700],
                          size: 24,
                        ),
                      ),
                      onPressed: () => setState(() {
                        _pickedImage = null;
                        _existingImageUrl = null;
                      }),
                    ),
                  ),
                if (_pickedImage != null || _existingImageUrl != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fullscreen_rounded,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                      ),
                      onPressed: () {
                        if (_existingImageUrl != null || _pickedImage != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                    title: const Text('صورة بطاقة الهوية')),
                                body: Center(
                                  child: _existingImageUrl != null
                                      ? Image.network(_existingImageUrl!)
                                      : Image.file(_pickedImage!),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Image.file(
      _pickedImage!,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
    );
  }

  Widget _buildAgeFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'أعمار الأفراد',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                '${_ageControllers.length}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._ageControllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: entry.value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'عمر الفرد ${index + 1}',
                labelStyle: const TextStyle(color: Colors.grey),
                floatingLabelStyle: TextStyle(color: AppColors.primaryColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
