import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

class TurnstileCaptcha extends StatelessWidget {
  final Function(String) onTokenReceived;

  const TurnstileCaptcha({super.key, required this.onTokenReceived});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      alignment: Alignment.center,
      child: CloudflareTurnstile(
        siteKey: '1x00000000000000000000AA', // testing site key
        baseUrl: 'http://localhost/', // Dummy baseUrl cần thiết cho mobile
        onTokenReceived: onTokenReceived,
      ),
    );
  }
}
