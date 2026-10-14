import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/site_client.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('DailyAds.pk', style: text.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Jobs, tenders, admissions, notices, property, court notices, auctions and results from Pakistan’s daily '
          'newspapers — collected every day and readable on your phone. Search the archive, filter by newspaper '
          'or city, and save the advertisements you want to come back to.',
          style: TextStyle(height: 1.5, color: Sheet.text2),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Sheet.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: const Text(
            'Not a government app. DailyAds.pk is an independent, privately run archive. It is not affiliated with, '
            'endorsed by or acting for any government department, advertiser or newspaper. Advertisements are '
            'reproduced from the newspapers that published them; each one links to its original source. '
            'Applications are never submitted through this app — always follow the instructions in the '
            'original advertisement and verify them on the advertiser’s official website.',
            style: TextStyle(height: 1.45, color: Sheet.accentText),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              subtitle: const Text('The app collects no personal data'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open('$siteOrigin/privacy-policy'),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms and conditions'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open('$siteOrigin/terms-and-conditions'),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Contact us'),
              subtitle: const Text('Report a problem or a wrong listing'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open('$siteOrigin/contact'),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Visit dailyads.pk'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(siteOrigin),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) => Text(
            snap.hasData ? 'Version ${snap.data!.version} (${snap.data!.buildNumber})' : '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Sheet.text3, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}
