import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationSection extends StatelessWidget {
  final String mealImageUrl;
  final String mealTitle;
  final String mealDescription;
  final List<ContactPerson> contacts;

  const DonationSection({
    super.key,
    required this.mealImageUrl,
    required this.mealTitle,
    required this.mealDescription,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: _MealHeader(imageUrl: mealImageUrl),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mealDescription,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'تواصل معنا للمساهمة ودعم المطبخ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio:
                    MediaQuery.of(context).size.width > 600 ? 0.8 : 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _DonorCard(contact: contacts[index]),
                childCount: contacts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealHeader extends StatelessWidget {
  final String imageUrl;

  const _MealHeader({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade100,
              child: const Icon(Icons.restaurant, size: 60, color: Colors.grey),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final ContactPerson contact;

  const _DonorCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Container(
                  width: isMobile ? 80 : 100,
                  height: isMobile ? 80 : 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: contact.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(contact.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey.shade100,
                  ),
                  child: contact.photoUrl == null
                      ? Icon(Icons.person,
                          size: isMobile ? 40 : 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      contact.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contact.role != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          contact.role!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _ContactTile(
                      icon: Icons.phone_iphone_rounded,
                      value: contact.formattedPhoneNumber,
                      onCopy: () =>
                          _copyToClipboard(contact.phoneNumber, context),
                    ),
                    if (contact.bankAccount != null) ...[
                      const SizedBox(height: 8),
                      _ContactTile(
                        icon: Icons.account_balance_wallet_rounded,
                        value: contact.bankAccount!,
                        onCopy: () =>
                            _copyToClipboard(contact.bankAccount!, context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 150) {
                    return Column(
                      children: _buildButtons(isMobile, context),
                    );
                  }
                  return Row(
                    children: _buildButtons(isMobile, context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtons(bool isMobile, BuildContext context) {
    return [
      Expanded(
        child: TextButton.icon(
          icon: Icon(Icons.copy_all_rounded,
              color: AppColors.primaryColor, size: isMobile ? 16 : 18),
          label: Text('نسخ',
              style: TextStyle(
                  color: AppColors.primaryColor, fontSize: isMobile ? 14 : 16)),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _copyToClipboard(contact.phoneNumber, context),
        ),
      ),
      SizedBox(width: isMobile ? 8 : 12),
      Expanded(
        child: FilledButton.icon(
          icon: Icon(Icons.chat_rounded, size: isMobile ? 16 : 18),
          label:
              Text('التواصل', style: TextStyle(fontSize: isMobile ? 14 : 16)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _launchWhatsApp(contact.phoneNumber),
        ),
      ),
    ];
  }

  void _launchWhatsApp(String number) async {
    final url = "https://wa.me/$number";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _copyToClipboard(String text, BuildContext context) {
    FlutterClipboard.copy(text).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم نسخ الرقم بنجاح")),
      );
    });
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onCopy;

  const _ContactTile({
    required this.icon,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onCopy,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: isMobile ? 20 : 22, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.copy_rounded,
                  size: isMobile ? 18 : 20, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactPerson {
  final String name;
  final String phoneNumber;
  final String? role;
  final String? photoUrl;
  final String? bankAccount;

  ContactPerson({
    required this.name,
    required this.phoneNumber,
    this.role,
    this.photoUrl,
    this.bankAccount,
  });

  String get formattedPhoneNumber =>
      '+${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
}
