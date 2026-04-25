import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math';

// We map multiple view types so we can instantiate multiple ads on the same page
final Map<String, bool> _registeredViews = {};

Widget buildWebBannerAd(double width, double height) {
  // Generate a random ID to ensure each ad block is unique
  final String viewId = 'adSense-banner-${Random().nextInt(100000)}';
  
  if (!_registeredViews.containsKey(viewId)) {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final html.DivElement container = html.DivElement()
        ..style.width = '${width}px'
        ..style.height = '${height}px'
        ..style.overflow = 'hidden'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center'
        ..style.backgroundColor = '#f1f1f1'; // Placeholder background

      // Create the AdSense element
      final html.Element ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'inline-block'
        ..style.width = '${width}px'
        ..style.height = '${height}px'
        ..setAttribute('data-ad-client', 'ca-pub-3940256099942544') // Sandbox/Test ID
        ..setAttribute('data-ad-slot', '1234567890');

      container.append(ins);

      // We trigger the ad loading by running the JS script
      final html.ScriptElement script = html.ScriptElement()
        ..type = 'text/javascript'
        ..innerHtml = '(adsbygoogle = window.adsbygoogle || []).push({});';
      container.append(script);

      return container;
    });
    _registeredViews[viewId] = true;
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewId),
  );
}
