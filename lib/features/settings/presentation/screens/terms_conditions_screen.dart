import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<TermSection> _sections = [
    TermSection(
      id: 'intro',
      category: 'General',
      title: '1. Acceptance of Terms',
      icon: Icons.gavel_rounded,
      content: 'Welcome to Yakut (referred to as "Yaqoot", "we", "us", or "our"). By downloading, installing, '
          'accessing, or using our mobile application and related services (collectively, the "Platform"), you '
          'agree to be bound by these Terms & Conditions ("Terms"). If you do not agree to these Terms, please '
          'do not access or use the Platform. We reserve the right to modify these Terms at any time, and your '
          'continued use of the Platform constitutes acceptance of the updated terms.',
    ),
    TermSection(
      id: 'accounts',
      category: 'Accounts',
      title: '2. User Accounts & Registration',
      icon: Icons.person_add_rounded,
      content: 'To access certain features of Yakut, including buying, selling, or live streaming, you must create '
          'an account. You agree to provide accurate, current, and complete information. You are solely responsible '
          'for maintaining the confidentiality of your credentials and for all activities that occur under your '
          'account. We support both Buyer and Seller profiles. Seller profiles may require additional verification, '
          'such as identity documents and financial details.',
    ),
    TermSection(
      id: 'streaming',
      category: 'Live & Content',
      title: '3. Live Streaming & Broadcast Rules',
      icon: Icons.live_tv_rounded,
      content: 'Yakut allows sellers to broadcast live streams to display and promote their products. By broadcasting, '
          'you agree not to stream any illegal, offensive, violent, or sexually explicit content. Streams must focus '
          'on legitimate commercial activities. We reserve the right to immediately terminate or suspend any live stream '
          'that violates community guidelines, acts inappropriately, or shows prohibited items. Users are responsible '
          'for any copyright infringement or unauthorized music used during broadcasts.',
    ),
    TermSection(
      id: 'selling',
      category: 'Live & Content',
      title: '4. Product Listings & Selling',
      icon: Icons.storefront_rounded,
      content: 'Sellers must list products with accurate descriptions, photos, and prices. The items listed must not '
          'be counterfeit, stolen, hazardous, or illegal. Sellers are responsible for keeping inventory updated. '
          'By listing an item, you warrant that you have legal ownership and authorization to sell it. Yakut reserves '
          'the right to charge commission fees or listing fees, which will be communicated in advance before listing.',
    ),
    TermSection(
      id: 'buying',
      category: 'Transactions',
      title: '5. Purchasing & Payments',
      icon: Icons.shopping_bag_rounded,
      content: 'Buyers agree to pay the stated price for products they purchase. Payments are processed securely via '
          'our designated payment gateways. Buyers must authorize payments using valid payment methods. Any purchase '
          'made during a live auction or stream is a binding contract. Return and refund policies are dictated by the '
          'respective seller, subject to Yakut\'s buyer protection program rules, which protect against fraudulent or '
          'undelivered goods.',
    ),
    TermSection(
      id: 'prohibited',
      category: 'Rules',
      title: '6. Prohibited Activities',
      icon: Icons.block_rounded,
      content: 'You may not use the Platform to: commit fraud, scam users, distribute malware, scrape platform data, '
          'harass or abuse other users, or conduct unauthorized advertising. Any attempt to bypass Yakut\'s transaction '
          'system to avoid platform fees (off-platform trading) is strictly prohibited and will result in permanent '
          'account termination.',
    ),
    TermSection(
      id: 'ip',
      category: 'General',
      title: '7. Intellectual Property Rights',
      icon: Icons.copyright_rounded,
      content: 'All source code, design, graphics, databases, and trademarks of Yakut are owned by or licensed to us. '
          'By uploading content (images, stream footage, descriptions) to Yakut, you grant us a worldwide, royalty-free, '
          'non-exclusive, perpetual license to use, display, modify, and distribute that content to promote the Platform.',
    ),
    TermSection(
      id: 'liability',
      category: 'General',
      title: '8. Limitation of Liability',
      icon: Icons.report_problem_rounded,
      content: 'Yakut is an intermediary platform connecting buyers and sellers. We do not inspect, test, or guarantee '
          'the quality, safety, or legality of items listed or the truthfulness of live stream claims. To the maximum '
          'extent permitted by law, Yakut is not liable for any direct, indirect, incidental, special, or consequential '
          'damages arising out of or in connection with your use of the Platform.',
    ),
    TermSection(
      id: 'disputes',
      category: 'Transactions',
      title: '9. Dispute Resolution & Governing Law',
      icon: Icons.balance_rounded,
      content: 'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in '
          'which Yakut operates, without regard to conflict of law principles. Any dispute arising from these terms '
          'or Platform use should first be attempted to be resolved amicably. If unresolved, disputes shall be submitted '
          'to binding arbitration in accordance with local regulations.',
    ),
    TermSection(
      id: 'contact',
      category: 'General',
      title: '10. Contact Us & Support',
      icon: Icons.mail_outline_rounded,
      content: 'If you have any questions, complaints, or feedback regarding these Terms & Conditions, please contact '
          'our support team at legal@yakut.app or visit the Support Center in the app settings.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TermSection> get _filteredSections {
    return _sections.where((section) {
      final matchesSearch = section.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          section.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || section.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'General', 'Accounts', 'Live & Content', 'Transactions', 'Rules'];
    final filtered = _filteredSections;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3),
                        const SizedBox(height: 6),
                        Text(
                          'Last updated: June 22, 2026',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search and Category Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search terms or keywords...',
                        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textHint),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),

                  // Category Pills
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecond,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Main content list
          if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text(
                        'No matching terms found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecond,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try searching for another keyword or check another category.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ExpandableTermCard(section: section),
                  ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, duration: 300.ms);
                },
                childCount: filtered.length,
              ),
            ),

          // Footer spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 48),
          ),
        ],
      ),
    );
  }
}

class TermSection {
  final String id;
  final String category;
  final String title;
  final IconData icon;
  final String content;

  TermSection({
    required this.id,
    required this.category,
    required this.title,
    required this.icon,
    required this.content,
  });
}

class ExpandableTermCard extends StatefulWidget {
  final TermSection section;

  const ExpandableTermCard({
    super.key,
    required this.section,
  });

  @override
  State<ExpandableTermCard> createState() => _ExpandableTermCardState();
}

class _ExpandableTermCardState extends State<ExpandableTermCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>(widget.section.id),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.section.icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            widget.section.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _isExpanded ? 0.5 : 0.0,
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 24),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.divider, height: 16),
                  const SizedBox(height: 8),
                  Text(
                    widget.section.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecond,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
