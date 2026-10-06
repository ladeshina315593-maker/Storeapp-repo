import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            child: Column(
            children: [
              const SizedBox(height: 20),

              // Submitted icon
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: pikkxBlack,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
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

              // Pending Review card
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: pikkxWhite,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pending Review',
                            style: TextStyle(
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
                      'Our team will review your application and notify you when there is an update.',
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

              // Review information
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        color: pikkxBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your application will be reviewed by the pikkX team. Once approved, you will be able to access your Merchant Dashboard.',
                      style: TextStyle(
                        color: Color(0x99050505),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}
