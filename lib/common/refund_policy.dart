import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@trusir.com',
      queryParameters: {'subject': 'Refund Request'},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+918582040204',
    );
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF48116A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refund Policy',
          style: TextStyle(
            color: Color(0xFF48116A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF48116A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.assignment_return,
                            color: Colors.white, size: 32),
                        SizedBox(height: 12),
                        Text(
                          'Our Refund Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fair and transparent refund process for all our tutoring services',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Policy Sections
                  _buildPolicySection(
                    title: '1. Eligibility for Refund',
                    icon: Icons.check_circle,
                    items: const [
                      'Tutor No-Show: If a confirmed tutor fails to attend without notice',
                      'Unsatisfactory First Session: Report within 24 hours',
                      'Mismatch of Requirements: If we can\'t provide suitable tutor',
                    ],
                  ),

                  _buildPolicySection(
                    title: '2. Non-Refundable Cases',
                    icon: Icons.cancel,
                    color: Colors.red[400],
                    items: const [
                      'Change of mind after sessions start',
                      'Missed sessions without 24h cancellation',
                      'Incomplete/inaccurate information provided',
                      'Late complaints after multiple sessions',
                    ],
                  ),

                  _buildPolicySection(
                    title: '3. How to Request',
                    icon: Icons.help_center,
                    items: const [
                      'Email: support@trusir.com',
                      'Call: +91 8582040204',
                      'Provide: Student name, tutor name, session dates',
                      'Request within 7 days of session',
                    ],
                    isContact: true,
                  ),

                  _buildPolicySection(
                    title: '4. Processing Timeline',
                    icon: Icons.schedule,
                    items: const [
                      'Approval decision within 3 business days',
                      'Refund processed in 7-10 working days',
                      'Credited via original payment method',
                      'Confirmation sent via email/SMS',
                    ],
                  ),

                  // Contact Card
                  Card(
                    margin: const EdgeInsets.only(top: 16, bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.contact_support,
                                  color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Need Help?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildContactTile(
                            icon: Icons.email,
                            label: 'Email us',
                            value: 'support@trusir.com',
                            onTap: _launchEmail,
                          ),
                          _buildContactTile(
                            icon: Icons.phone,
                            label: 'Call us',
                            value: '+91 8582040204',
                            onTap: _launchPhone,
                          ),
                          _buildContactTile(
                            icon: Icons.location_on,
                            label: 'Visit us',
                            value:
                                '1st floor, trusir.com, Station Rd, Motihari, Bihar 845401',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required IconData icon,
    required List<String> items,
    Color? color,
    bool isContact = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? const Color(0xFF48116A), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color ?? const Color(0xFF48116A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isContact ? '• ' : '✓ ',
                      style: TextStyle(
                        color: color ?? const Color(0xFF48116A),
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
