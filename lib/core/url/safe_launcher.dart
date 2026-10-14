import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafeLauncher {
  static Future<void> launchSafe(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    
    final uri = Uri.tryParse(urlString);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or insecure URL')),
        );
      }
      return;
    }
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening link')),
        );
      }
    }
  }
}
