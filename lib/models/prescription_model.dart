import 'package:flutter/material.dart';

class PrescriptionModel {
  final String id;
  final String requestNumber; // Ex: REQ-8829
  final String patientName;
  final String initials;
  final int patientAge;
  final String patientGender; // 'Homme', 'Femme'
  final String timeAgo;
  final String status; // 'URGENT', 'ROUTINE', 'PENDING', 'NOUVEAU', 'EN ATTENTE'
  final List<String> tests;
  final Color avatarColor;
  final String doctorName;
  final String doctorSpecialty;
  final String clinicalContext;

  PrescriptionModel({
    required this.id,
    required this.requestNumber,
    required this.patientName,
    required this.initials,
    required this.patientAge,
    required this.patientGender,
    required this.timeAgo,
    required this.status,
    required this.tests,
    required this.avatarColor,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.clinicalContext,
  });
}
