import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/calendar_event_model.dart';
import '../../providers/calendar_provider.dart';
import 'add_consultation_dialog.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        final selectedEvents = calendarProvider.getEventsForDay(calendarProvider.selectedDay);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
              stops: const [0, 0.3],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildCalendar(calendarProvider),
                const SizedBox(height: 8),
                _buildEventTypeLegend(),
                const SizedBox(height: 8),
                Expanded(
                  child: selectedEvents.isEmpty
                      ? _buildEmptyState()
                      : _buildEventsList(selectedEvents),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mon Agenda',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Planifiez vos consultations et opérations',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showAddConsultationDialog(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColors.neonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildCalendar(CalendarProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: provider.focusedDay,
        selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'fr_FR',
        eventLoader: (day) => provider.getEventsForDay(day),
        onDaySelected: (selectedDay, focusedDay) {
          provider.setSelectedDay(selectedDay);
          provider.setFocusedDay(focusedDay);
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          provider.setFocusedDay(focusedDay);
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
          defaultTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markersMaxCount: 3,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            gradient: AppColors.neonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left, color: AppColors.primary, size: 20),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          weekendStyle: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((event) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: event.type.color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventTypeLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: EventType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: type.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  type.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final dateStr = DateFormat('d MMMM yyyy', 'fr_FR').format(provider.selectedDay);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun événement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showAddConsultationDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.neonGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ajouter un événement',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _animController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
          child: _buildEventCard(event),
        );
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final timeStr = DateFormat('HH:mm').format(event.dateTime);
    final endStr = event.endTime != null ? ' - ${DateFormat('HH:mm').format(event.endTime!)}' : '';
    final color = event.type.color;

    return GestureDetector(
      onTap: () => _showEventDetails(context, event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Time column
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(event.type.icon, color: Colors.white, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.type.lightColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.type.displayName,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        '$timeStr$endStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (event.patientName != null && event.patientName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          event.patientName!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Alert indicator
            if (event.alertBefore != AlertOption.none)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== ADD EVENT BOTTOM SHEET ====================

  void _showAddEventSheet(BuildContext context, {CalendarEvent? existingEvent}) {
    final isEditing = existingEvent != null;
    final titleController = TextEditingController(text: existingEvent?.title ?? '');
    final descController = TextEditingController(text: existingEvent?.description ?? '');
    final patientController = TextEditingController(text: existingEvent?.patientName ?? '');
    EventType selectedType = existingEvent?.type ?? EventType.consultation;
    AlertOption selectedAlert = existingEvent?.alertBefore ?? AlertOption.min15;
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    DateTime selectedDate = existingEvent?.dateTime ?? provider.selectedDay;
    TimeOfDay selectedTime = existingEvent != null
        ? TimeOfDay.fromDateTime(existingEvent.dateTime)
        : TimeOfDay.now();
    TimeOfDay? selectedEndTime = existingEvent?.endTime != null
        ? TimeOfDay.fromDateTime(existingEvent!.endTime!)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_rounded : Icons.add_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              isEditing ? 'Modifier l\'événement' : 'Nouvel événement',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Event type selector
                        const Text(
                          'Type d\'événement',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: EventType.values.map((type) {
                            final isSelected = selectedType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() => selectedType = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(colors: [type.color, type.color.withValues(alpha: 0.7)])
                                        : null,
                                    color: isSelected ? null : type.lightColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : type.color.withValues(alpha: 0.3),
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: type.color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(type.icon, color: isSelected ? Colors.white : type.color, size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        type.displayName,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : type.color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Title field
                        _buildFormField(
                          controller: titleController,
                          label: 'Titre',
                          hint: 'Ex: Consultation Dr. Martin',
                          icon: Icons.title_rounded,
                        ),
                        const SizedBox(height: 16),

                        // Patient field
                        _buildFormField(
                          controller: patientController,
                          label: 'Patient (optionnel)',
                          hint: 'Nom du patient',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        // Description field
                        _buildFormField(
                          controller: descController,
                          label: 'Description (optionnel)',
                          hint: 'Notes supplémentaires...',
                          icon: Icons.note_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Date & Time
                        const Text(
                          'Date et heure',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTimePicker(
                                icon: Icons.calendar_today_rounded,
                                label: DateFormat('dd/MM/yyyy').format(selectedDate),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedDate = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateTimePicker(
                                icon: Icons.access_time_rounded,
                                label: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedTime = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDateTimePicker(
                          icon: Icons.timelapse_rounded,
                          label: selectedEndTime != null
                              ? 'Fin: ${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}'
                              : 'Heure de fin (optionnel)',
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedEndTime ?? selectedTime,
                            );
                            if (picked != null) {
                              setSheetState(() => selectedEndTime = picked);
                            }
                          },
                          isOptional: selectedEndTime == null,
                        ),
                        const SizedBox(height: 24),

                        // Alert selector
                        const Text(
                          'Alerte / Rappel',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AlertOption.values.map((alert) {
                            final isSelected = selectedAlert == alert;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedAlert = alert),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? AppColors.neonGradient : null,
                                  color: isSelected ? null : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected ? null : Border.all(color: AppColors.border),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
                                      ),
                                    Text(
                                      alert.displayName,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // Submit button
                        GestureDetector(
                          onTap: () {
                            if (titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Veuillez entrer un titre'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }

                            final dateTimeEvent = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );

                            DateTime? endTimeEvent;
                            if (selectedEndTime != null) {
                              endTimeEvent = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedEndTime!.hour,
                                selectedEndTime!.minute,
                              );
                            }

                            final event = CalendarEvent(
                              id: isEditing ? existingEvent.id : DateTime.now().millisecondsSinceEpoch.toString(),
                              title: titleController.text.trim(),
                              description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                              dateTime: dateTimeEvent,
                              endTime: endTimeEvent,
                              type: selectedType,
                              alertBefore: selectedAlert,
                              patientName: patientController.text.trim().isEmpty ? null : patientController.text.trim(),
                            );

                            if (isEditing) {
                              provider.updateEvent(event);
                            } else {
                              provider.addEvent(event);
                            }

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? 'Événement modifié ✓' : 'Événement ajouté ✓'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [selectedType.color, selectedType.color.withValues(alpha: 0.8)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: selectedType.color.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing ? Icons.check_rounded : Icons.add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isEditing ? 'Enregistrer les modifications' : 'Ajouter l\'événement',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isOptional = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isOptional ? AppColors.textLight : AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isOptional ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EVENT DETAILS BOTTOM SHEET ====================

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    final color = event.type.color;
    final provider = Provider.of<CalendarProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)],
                          ),
                          child: Icon(event.type.icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: event.type.lightColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  event.type.displayName,
                                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Info rows
                    _buildDetailRow(
                      Icons.calendar_today_rounded,
                      'Date',
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(event.dateTime),
                      color,
                    ),
                    _buildDetailRow(
                      Icons.access_time_rounded,
                      'Heure',
                      '${DateFormat('HH:mm').format(event.dateTime)}${event.endTime != null ? ' - ${DateFormat('HH:mm').format(event.endTime!)}' : ''}',
                      color,
                    ),
                    if (event.patientName != null && event.patientName!.isNotEmpty)
                      _buildDetailRow(Icons.person_outline_rounded, 'Patient', event.patientName!, color),
                    if (event.alertBefore != AlertOption.none)
                      _buildDetailRow(
                        Icons.notifications_active_rounded,
                        'Alerte',
                        event.alertBefore.displayName,
                        AppColors.warning,
                      ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.description!,
                              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showAddEventSheet(context, existingEvent: event);
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: color.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: color),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modifier',
                                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              provider.deleteEvent(event.id);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Événement supprimé'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddConsultationDialog(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    print('🔔 Opening consultation dialog for date: ${provider.selectedDay}');
    
    try {
      showDialog(
        context: context,
        builder: (context) => AddConsultationDialog(
          selectedDate: provider.selectedDay,
        ),
      );
    } catch (e) {
      print('❌ Error opening dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
