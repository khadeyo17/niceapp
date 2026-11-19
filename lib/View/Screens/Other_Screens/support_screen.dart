import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:niceapp/View/Screens/Other_Screens/report_support_issue_screen.dart';

import 'my_issues_screen.dart';


class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Widget _supportOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF015ACE), size: 25),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black38,
        ),
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
        title: Text(
          'Support',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Report an issue or track your existing support requests.',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 22),

            _supportOption(
              context: context,
              icon: Icons.report_problem_outlined,
              title: 'Report an Issue',
              description: 'Tell us about a problem with the app or service.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportSupportIssueScreen(),
                  ),
                );
              },
            ),

            _supportOption(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'My Issues',
              description: 'View your reported issues and their status.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyIssuesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'my_issues_screen.dart';

// class SupportScreen extends StatelessWidget {
//   const SupportScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9F9),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         foregroundColor: Colors.black,
//         title: Text(
//           'Support',
//           style: GoogleFonts.spaceGrotesk(
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Your support requests',
//               style: GoogleFonts.spaceGrotesk(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'View and track issues you have reported.',
//               style: GoogleFonts.nunitoSans(
//                 fontSize: 14,
//                 color: Colors.black54,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF1F2F4),
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: ListTile(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const MyIssuesScreen(),
//                     ),
//                   );
//                 },
//                 contentPadding: const EdgeInsets.all(14),
//                 leading: Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(
//                     Icons.receipt_long_outlined,
//                     color: Color(0xFF015ACE),
//                     size: 25,
//                   ),
//                 ),
//                 title: Text(
//                   'My Issues',
//                   style: GoogleFonts.spaceGrotesk(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 16,
//                   ),
//                 ),
//                 subtitle: Text(
//                   'View reported issues and their resolution status.',
//                   style: GoogleFonts.nunitoSans(
//                     fontSize: 13,
//                     color: Colors.black54,
//                   ),
//                 ),
//                 trailing: const Icon(
//                   Icons.chevron_right,
//                   color: Colors.black38,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';

// // class SupportScreen extends StatelessWidget {
// //   const SupportScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF9F9F9),

// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 1,
// //         foregroundColor: Colors.black,
// //         title: Text(
// //           "Support",
// //           style: GoogleFonts.spaceGrotesk(
// //             fontSize: 20,
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //         centerTitle: true,
// //       ),

// //       body: Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           children: [
// //             _supportOption(
// //               icon: Icons.support_agent_outlined,
// //               title: "Contact Support",
// //               description:
// //                   "Talk to our support team about your account or trip.",
// //               onTap: () {},
// //             ),

// //             _supportOption(
// //               icon: Icons.report_problem_outlined,
// //               title: "Report a Problem",
// //               description:
// //                   "Tell us about an issue you experienced.",
// //               onTap: () {},
// //             ),

// //             _supportOption(
// //               icon: Icons.receipt_long_outlined,
// //               title: "Trip Issue",
// //               description:
// //                   "Get help with a completed or ongoing trip.",
// //               onTap: () {},
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _supportOption({
// //     required IconData icon,
// //     required String title,
// //     required String description,
// //     required VoidCallback onTap,
// //   }) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 12),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF1F2F4),
// //         borderRadius: BorderRadius.circular(15),
// //       ),
// //       child: ListTile(
// //         onTap: onTap,
// //         contentPadding: const EdgeInsets.all(12),
// //         leading: Container(
// //           width: 44,
// //           height: 44,
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: const Icon(
// //             Icons.support_agent_outlined,
// //             color: Color(0xFF015ACE),
// //           ),
// //         ),
// //         title: Text(
// //           title,
// //           style: GoogleFonts.spaceGrotesk(
// //             fontWeight: FontWeight.w600,
// //             fontSize: 16,
// //           ),
// //         ),
// //         subtitle: Text(
// //           description,
// //           style: GoogleFonts.nunitoSans(
// //             fontSize: 13,
// //             color: Colors.black54,
// //           ),
// //         ),
// //         trailing: const Icon(
// //           Icons.chevron_right,
// //           color: Colors.black38,
// //         ),
// //       ),
// //     );
// //   }
// // }