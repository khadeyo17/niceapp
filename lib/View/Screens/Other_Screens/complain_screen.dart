import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_issue_service.dart';
import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';

class ComplaintScreen extends StatefulWidget {
  final RideHistory ride;

  const ComplaintScreen({
    super.key,
    required this.ride,
  });

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isSubmitting = false;

  static const Color primaryColor = Color(0xFF015ACE);
  String _selectedIssueCategory = 'Driver Conduct';

final List<String> _issueCategories = [
  'Driver Conduct',
  'Passenger Conduct',
  'Vehicle Condition',
  'Payment Issues',
  'Trip / Route Issues',
  'Safety Concerns',
  'Lost Items',
  'App / Technical Issues',
  'Other',
];




  Future<void> submitComplaint() async {
  final description = _controller.text.trim();

  if (description.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please describe the issue before submitting.'),
      ),
    );
    return;
  }

  if (description.length < 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please provide at least 5 characters.'),
      ),
    );
    return;
  }

  if (_isSubmitting) return;

  final passengerUid = FirebaseAuth.instance.currentUser?.uid;
  final driverUid = widget.ride.driverId;

  if (passengerUid == null || passengerUid.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to identify the passenger. Please sign in again.')),
    );
    return;
  }

  if (driverUid == null || driverUid.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver information is unavailable for this ride.')),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final result = await RideIssueService.submitIssue(
      rideId: widget.ride.id,
      reportedByRole: 'Passenger',

      // Firebase UIDs
      passengerId: passengerUid,
      driverId: driverUid,

      vehicleRegistrationNumber:
          widget.ride.registrationNumber ?? '',

      driverName: widget.ride.contactName ?? '',
      passengerName: '',

      pickup: widget.ride.pickupLocation ?? '',
      destination: widget.ride.destination ?? '',

      description: description,
      issueCategory: _selectedIssueCategory,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message'] ??
              'Your issue has been submitted successfully.',
        ),
        backgroundColor: const Color(0xFF0E9E8C),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

  Widget _detailField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Not available' : value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Report an Issue',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us what went wrong',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your trip details are automatically attached to this report.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 22),

              // RIDE DETAILS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRIP DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _detailField(
                      'VEHICLE REGISTRATION',
                      widget.ride.registrationNumber ?? '',
                      Icons.directions_car_outlined,
                    ),

                    _detailField(
                      'DRIVER',
                      widget.ride.contactName ?? '',
                      Icons.person_outline,
                    ),

                    _detailField(
                      'PICKUP LOCATION',
                      widget.ride.pickupLocation ?? '',
                      Icons.my_location_outlined,
                    ),

                    _detailField(
                      'DESTINATION',
                      widget.ride.destination ?? '',
                      Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              DropdownButtonFormField<String>(
  value: _selectedIssueCategory,
  decoration: InputDecoration(
    labelText: 'Issue Category',
    labelStyle: GoogleFonts.nunitoSans(
      fontSize: 14,
      color: Colors.black54,
    ),
    prefixIcon: const Icon(
      Icons.category_outlined,
      color: Color(0xFF015ACE),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 15,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF015ACE),
        width: 1.5,
      ),
    ),
  ),
  items: _issueCategories.map((category) {
    return DropdownMenuItem<String>(
      value: category,
      child: Text(
        category,
        style: GoogleFonts.nunitoSans(fontSize: 14),
      ),
    );
  }).toList(),
  onChanged: (value) {
    if (value != null) {
      setState(() => _selectedIssueCategory = value);
    }
  },
),
 const SizedBox(height: 22),
              const Text(
                'DESCRIBE YOUR ISSUE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _controller,
                maxLines: 6,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Please explain what happened during your trip...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        primaryColor.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 21,
                          width: 21,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Our support team will review your report.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

