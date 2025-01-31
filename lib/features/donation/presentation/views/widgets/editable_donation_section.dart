import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import '../../../../manage_cases/donation_section.dart';
import '../../cubit/donation_cubit.dart';

class EditableDonationSection extends StatefulWidget {
  final Map<String, dynamic> donationData;

  const EditableDonationSection({super.key, required this.donationData});

  @override
  State<EditableDonationSection> createState() =>
      _EditableDonationSectionState();
}

class _EditableDonationSectionState extends State<EditableDonationSection> {
  late TextEditingController _mealImageUrlController;
  late TextEditingController _mealTitleController;
  late TextEditingController _mealDescriptionController;
  late List<ContactPerson> _contacts;

  @override
  void initState() {
    super.initState();
    _mealImageUrlController =
        TextEditingController(text: widget.donationData['mealImageUrl']);
    _mealTitleController =
        TextEditingController(text: widget.donationData['mealTitle']);
    _mealDescriptionController =
        TextEditingController(text: widget.donationData['mealDescription']);
    _contacts =
        List.from(widget.donationData['contacts'] as List<ContactPerson>);
  }

  void saveChanges() {
    final newData = {
      'mealImageUrl': _mealImageUrlController.text,
      'mealTitle': _mealTitleController.text,
      'mealDescription': _mealDescriptionController.text,
      'contacts': _contacts,
    };
    context.read<DonationCubit>().updateDonationData(newData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
    );
  }

  void updateContact(int index, ContactPerson newContact) {
    setState(() {
      _contacts[index] = newContact;
    });
  }

  void removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  void addContact() {
    setState(() {
      _contacts.add(ContactPerson(
        name: '',
        phoneNumber: '',
        role: '',
        bankAccount: '',
      ));
    });
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
            _buildImageUrlField(),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUrlField() {
    return TextFormField(
      controller: _mealImageUrlController,
      decoration: InputDecoration(
        labelText: 'رابط صورة الوجبة',
        hintText: 'https://example.com/image.jpg',
        prefixIcon: const Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _mealTitleController,
      decoration: InputDecoration(
        labelText: 'عنوان الوجبة',
        hintText: 'أدخل عنواناً جذاباً للوجبة',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
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
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('جهات الاتصال', Icons.contacts),
        ..._contacts.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContactEditor(
                contact: entry.value,
                onChanged: (newContact) => updateContact(entry.key, newContact),
                onRemove: () => removeContact(entry.key),
              ),
            )),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('إضافة جهة اتصال جديدة'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: addContact,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.save_alt, size: 24),
          SizedBox(width: 8),
          Text('حفظ التغييرات', style: TextStyle(fontSize: 16)),
        ],
      ),
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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _bankController;

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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildContactField(
              controller: _nameController,
              label: 'الاسم الكامل',
              icon: Icons.person,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              controller: _roleController,
              label: 'الدور/المسمى الوظيفي',
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              controller: _bankController,
              label: 'الحساب البنكي',
              icon: Icons.account_balance,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('حذف جهة الاتصال'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: widget.onRemove,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => _updateContact(),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  void _updateContact() {
    widget.onChanged(ContactPerson(
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      role: _roleController.text,
      bankAccount: _bankController.text,
    ));
  }
}
