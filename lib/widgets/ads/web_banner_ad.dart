import 'package:flutter/material.dart';

// Conditional import to support web without breaking mobile
import 'web_banner_ad_stub.dart'
    if (dart.library.js_interop) 'web_banner_ad_web.dart';

class WebBannerAdWidget extends StatelessWidget {
  final double width;
  final double height;
  
  const WebBannerAdWidget({
    super.key,
    this.width = 320,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.hardEdge,
      child: buildWebBannerAd(width, height),
    );
  }
}
