import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_issue_service.dart';


class ReportSupportIssueScreen extends StatefulWidget {
  const ReportSupportIssueScreen({super.key});

  @override
  State<ReportSupportIssueScreen> createState() =>
      _ReportSupportIssueScreenState();
}

class _ReportSupportIssueScreenState
    extends State<ReportSupportIssueScreen> {
  final TextEditingController _descriptionController =
      TextEditingController();

  final List<String> _categories = [
    'Payment Issues',
    'App / Technical Issues',
    'Account Issues',
    'Booking Issues',
    'Safety Concerns',
    'Lost Items',
    'Other',
  ];

  String _selectedCategory = 'App / Technical Issues';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    final description = _descriptionController.text.trim();

    if (description.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 5 characters.'),
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await RideIssueService.submitIssue(
        rideId: null,
        reportedByRole: 'Passenger',
        vehicleRegistrationNumber: '',
        driverName: '',
        passengerName: '',
        pickup: '',
        destination: '',
        description: description,
        passengerId: null,
        driverId: null,
        issueCategory: _selectedCategory,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Your issue has been submitted.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          'Report an Issue',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What went wrong?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a category and describe the issue. Our support team will review your report.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),

              Text(
                'Issue category',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(
                  hint: 'Select issue category',
                  icon: Icons.category_outlined,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.nunitoSans(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
              ),

              const SizedBox(height: 22),

              Text(
                'Description',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                minLines: 6,
                maxLines: 8,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hint: 'Please explain the issue you are experiencing...',
                  icon: Icons.edit_note_outlined,
                ).copyWith(
                  alignLabelWithHint: true,
                  prefixIcon: null,
                ),
                style: GoogleFonts.nunitoSans(fontSize: 14),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF015ACE),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF015ACE).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                      : Text(
                          'Submit Issue',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunitoSans(
        fontSize: 13,
        color: Colors.black38,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF015ACE)),
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
    );
  }
}