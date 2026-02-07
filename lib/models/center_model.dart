class CenterModel {
  String name;
  String category;
  String phone;
  String email;
  String location;
  bool onlineAppointmentEnabled;
  Map<String, DaySchedule> openingHours;

  CenterModel({
    this.name = '',
    this.category = '',
    this.phone = '',
    this.email = '',
    this.location = '',
    this.onlineAppointmentEnabled = false,
    Map<String, DaySchedule>? openingHours,
  }) : openingHours = openingHours ?? {
          'Lundi': DaySchedule(isOpen: true, startTime: '08:00 AM', endTime: '06:30 PM'),
          'Mardi': DaySchedule(isOpen: true, startTime: '08:00 AM', endTime: '06:30 PM'),
          'Mercredi': DaySchedule(isOpen: true, startTime: '08:00 AM', endTime: '06:30 PM'),
          'Jeudi': DaySchedule(isOpen: true, startTime: '08:00 AM', endTime: '06:30 PM'),
          'Vendredi': DaySchedule(isOpen: true, startTime: '08:00 AM', endTime: '05:00 PM'),
          'Samedi': DaySchedule(isOpen: false),
          'Dimanche': DaySchedule(isOpen: false),
        };
}

class DaySchedule {
  bool isOpen;
  String startTime;
  String endTime;

  DaySchedule({
    required this.isOpen,
    this.startTime = '',
    this.endTime = '',
  });
}
