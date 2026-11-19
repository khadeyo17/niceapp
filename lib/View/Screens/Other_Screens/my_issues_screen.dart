import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_issue_service.dart';


class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  List<Map<String, dynamic>> _issues = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final issues = await RideIssueService.getMyIssues();

      if (!mounted) return;

      setState(() {
        _issues = issues;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not available';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Not available';

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return const Color(0xFF0E9E8C);
      case 'pending':
        return const Color(0xFFE39A19);
      case 'in progress':
      case 'processing':
        return const Color(0xFF015ACE);
      case 'rejected':
        return const Color(0xFF777777);
      default:
        return const Color(0xFF777777);
    }
  }

  Widget _buildIssueCard(Map<String, dynamic> issue) {
    final status = issue['status']?.toString() ?? 'Pending';
    final category = issue['issueCategory']?.toString() ?? 'General';
    final description = issue['description']?.toString() ?? '';
    final createdAt = issue['createdAt'];
    final resolvedAt = issue['resolvedAt'];
    final rideId = issue['rideId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          if (rideId != null)
            _dateRow(
              Icons.receipt_long_outlined,
              'Ride reference',
              '#$rideId',
            ),

          _dateRow(
            Icons.calendar_today_outlined,
            'Date reported',
            _formatDate(createdAt),
          ),

          _dateRow(
            Icons.check_circle_outline,
            'Date resolved',
            resolvedAt == null
                ? 'Not yet resolved'
                : _formatDate(resolvedAt),
          ),

          if ((issue['resolutionNotes'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resolution notes',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issue['resolutionNotes'].toString(),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.black45),
          const SizedBox(width: 9),
          Text(
            '$label:',
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF015ACE),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Colors.black38,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _loadIssues,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF015ACE),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_issues.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadIssues,
        color: const Color(0xFF015ACE),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(
              Icons.inbox_outlined,
              size: 65,
              color: Colors.black26,
            ),
            const SizedBox(height: 15),
            Text(
              'No issues reported',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Issues you report will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIssues,
      color: const Color(0xFF015ACE),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _issues.length,
        itemBuilder: (context, index) {
          return _buildIssueCard(_issues[index]);
        },
      ),
    );
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
          'My Issues',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}