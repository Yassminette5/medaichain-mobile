import 'package:flutter/material.dart';

class PrescriptionModel {
  final String id;
  final String patientName;
  final String initials;
  final String timeAgo;
  final String status; // 'URGENT', 'ROUTINE', 'PENDING'
  final List<String> tests;
  final Color avatarColor;

  PrescriptionModel({
    required this.id,
    required this.patientName,
    required this.initials,
    required this.timeAgo,
    required this.status,
    required this.tests,
    required this.avatarColor,
  });
}
