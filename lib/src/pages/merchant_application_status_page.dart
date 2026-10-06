import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MerchantApplicationStatusPage extends StatelessWidget {
  final String applicationId;

  const MerchantApplicationStatusPage({
    super.key,
    required this.applicationId,
  });

  static const Color pikkxBlack = Color(0xFF050505);
  static const Color pikkxWhite = Color(0xFFFFFFFF);
  static const Color pikkxBackground = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkxBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: pikkxBlack,
          ),
        ),
        title: const Text(
          'Application Status',
          style: TextStyle(
            color: pikkxBlack,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('merchantApplications')
            .doc(applicationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load application status.',
                style: TextStyle(
                  color: pikkxBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: pikkxBlack,
              ),
            );
          }

          final data = snapshot.data?.data();
          final status =
              (data?['status'] ?? 'pending').toString().toLowerCase();

          final statusTitle = status == 'approved'
              ? 'Approved'
              : status == 'rejected'
                  ? 'Rejected'
                  : status == 'needs_changes'
                      ? 'Needs Changes'
                      : 'Pending Review';

          final statusIcon = status == 'approved'
              ? Icons.check_circle_rounded
              : status == 'rejected'
                  ? Icons.cancel_rounded
                  : status == 'needs_changes'
                      ? Icons.edit_note_rounded
                      : Icons.schedule_rounded;

          final statusMessage = status == 'approved'
              ? 'Your merchant application has been approved. Your Merchant Dashboard is now available.'
              : status == 'rejected'
                  ? 'Your merchant application was not approved. Please contact pikkX support for more information.'
                  : status == 'needs_changes'
                      ? 'Some changes are required before your application can be approved.'
                      : 'Your application is currently being reviewed by the pikkX team. You will be notified when there is an update.';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Status icon
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: pikkxBlack,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      statusIcon,
                      color: pikkxWhite,
                      size: 44,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Application Submitted!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pikkxBlack,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Your merchant application has been received successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pikkxBlack.withOpacity(0.60),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Application status card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: pikkxWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: pikkxBlack.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: pikkxBlack.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'APPLICATION STATUS',
                          style: TextStyle(
                            color: pikkxBlack.withOpacity(0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: pikkxBlack,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                color: pikkxWhite,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusTitle,
                                style: const TextStyle(
                                  color: pikkxWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: pikkxBlack.withOpacity(0.58),
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Application information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: pikkxWhite.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: pikkxBlack.withOpacity(0.07),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What happens next?',
                          style: TextStyle(
                            color: pikkxBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          status == 'approved'
                              ? 'You can now continue to your Merchant Dashboard and start managing your store.'
                              : 'Your application will be reviewed by the pikkX team. You will receive an update when your application status changes.',
                          style: TextStyle(
                            color: pikkxBlack.withOpacity(0.60),
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pikkxBlack,
                        foregroundColor: pikkxWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        status == 'approved'
                            ? 'Continue'
                            : 'Back to Profile',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}