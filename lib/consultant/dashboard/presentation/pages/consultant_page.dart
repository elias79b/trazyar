import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/consultant/dashboard/application/consultant_dashboard_provider.dart';
import 'package:tarazyar/consultant/dashboard/data/models/consultant_event_model.dart';
import 'package:tarazyar/consultant/dashboard/data/models/consultant_note_model.dart';

import '../widgets/consultant_scaffold.dart';

class ConsultantPage extends ConsumerWidget {
  const ConsultantPage({super.key});

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state =
    ref.watch(consultantDashboardProvider);

    return ConsultantScaffold(
      currentRoute: '/consultant',
      title: 'داشبورد مشاور',
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(
              consultantDashboardProvider,
            );
          },
        ),
        data: (data) {
          return _DashboardBody(
            data: data,
            onRefresh: () {
              ref.invalidate(
                consultantDashboardProvider,
              );
            },
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* DASHBOARD                                                                  */
/* -------------------------------------------------------------------------- */

class _DashboardBody extends StatelessWidget {
  final ConsultantDashboardData data;
  final VoidCallback onRefresh;

  const _DashboardBody({
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return SingleChildScrollView(
            padding: EdgeInsets.all(
              width >= 1200 ? 24 : 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                _Header(data: data),

                const SizedBox(height: 18),

                _Kpis(data: data),

                const SizedBox(height: 18),

                _CalendarNotesSection(
                  data: data,
                  onRefresh: onRefresh,
                ),

                const SizedBox(height: 18),

                _EventsSection(
                  events: data.events,
                  onRefresh: onRefresh,
                ),

                const SizedBox(height: 18),

                _CompanyComparison(
                  companies: data.companies,
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HEADER                                                                     */
/* -------------------------------------------------------------------------- */

class _Header extends StatelessWidget {
  final ConsultantDashboardData data;

  const _Header({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 112,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B4332),
            Color(0xFF2D6A4F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF1B4332),
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'سلام، مشاور عزیز',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'نمای کلی فعالیت‌ها و شرکت‌های تحت مدیریت شما',
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fa(data.companies.length)} شرکت تحت پوشش شماست',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* KPI                                                                        */
/* -------------------------------------------------------------------------- */

class _Kpis extends StatelessWidget {
  final ConsultantDashboardData data;

  const _Kpis({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final int count;

        if (width >= 1100) {
          count = 4;
        } else if (width >= 650) {
          count = 2;
        } else {
          count = 1;
        }

        const gap = 12.0;

        final itemWidth = count == 1
            ? width
            : (width - ((count - 1) * gap)) /
            count;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'شرکت‌های تحت پوشش',
                value:
                _fa(data.companies.length),
                icon:
                Icons.business_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'اقدامات باز',
                value:
                _fa(data.pendingEvents),
                icon: Icons
                    .pending_actions_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'فعالیت‌های امروز',
                value:
                _fa(data.todayEvents),
                icon: Icons.today_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'هشدارهای مهم',
                value:
                _fa(data.highPriorityEvents),
                icon: Icons
                    .priority_high_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color:
              const Color(0xFF1B4332)
                  .withOpacity(.09),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color:
              const Color(0xFF1B4332),
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w900,
                    color:
                    Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* CALENDAR + NOTES                                                           */
/* -------------------------------------------------------------------------- */

class _CalendarNotesSection
    extends StatelessWidget {
  final ConsultantDashboardData data;
  final VoidCallback onRefresh;

  const _CalendarNotesSection({
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _PersianCalendar(
                  events: data.events,
                  onRefresh: onRefresh,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _NotesCard(
                  notes: data.notes,
                  onRefresh: onRefresh,
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PersianCalendar(
              events: data.events,
              onRefresh: onRefresh,
            ),
            const SizedBox(height: 16),
            _NotesCard(
              notes: data.notes,
              onRefresh: onRefresh,
            ),
          ],
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* PERSIAN CALENDAR                                                            */
/* -------------------------------------------------------------------------- */

class _PersianCalendar extends StatefulWidget {
  final List<ConsultantEvent> events;
  final VoidCallback onRefresh;

  const _PersianCalendar({
    required this.events,
    required this.onRefresh,
  });

  @override
  State<_PersianCalendar> createState() =>
      _PersianCalendarState();
}

class _PersianCalendarState
    extends State<_PersianCalendar> {
  late Jalali _month;

  @override
  void initState() {
    super.initState();

    final now = Jalali.fromDateTime(
      DateTime.now(),
    );

    _month = Jalali(
      now.year,
      now.month,
      1,
    );
  }

  void _previousMonth() {
    setState(() {
      if (_month.month == 1) {
        _month = Jalali(
          _month.year - 1,
          12,
          1,
        );
      } else {
        _month = Jalali(
          _month.year,
          _month.month - 1,
          1,
        );
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month.month == 12) {
        _month = Jalali(
          _month.year + 1,
          1,
          1,
        );
      } else {
        _month = Jalali(
          _month.year,
          _month.month + 1,
          1,
        );
      }
    });
  }

  void _goToday() {
    final now =
    Jalali.fromDateTime(
      DateTime.now(),
    );

    setState(() {
      _month = Jalali(
        now.year,
        now.month,
        1,
      );
    });
  }

  List<ConsultantEvent> _eventsForDay(
      int day,
      ) {
    return widget.events.where((event) {
      final j =
      Jalali.fromDateTime(
        event.eventDate,
      );

      return j.year == _month.year &&
          j.month == _month.month &&
          j.day == day;
    }).toList();
  }

  int _daysInMonth() {
    final first =
    Jalali(
      _month.year,
      _month.month,
      1,
    ).toDateTime();

    final next = _month.month == 12
        ? Jalali(
      _month.year + 1,
      1,
      1,
    ).toDateTime()
        : Jalali(
      _month.year,
      _month.month + 1,
      1,
    ).toDateTime();

    return next
        .difference(first)
        .inDays;
  }

  @override
  Widget build(BuildContext context) {
    final days =
    _daysInMonth();

    final firstDay =
    Jalali(
      _month.year,
      _month.month,
      1,
    );

    /*
     * شنبه = 0
     */
    final firstWeekDay =
        (firstDay.weekDay + 1) % 7;

    final totalCells =
        ((firstWeekDay + days + 6) ~/ 7) *
            7;

    return _DashboardCard(
      title: 'تقویم فعالیت‌های من',
      subtitle:
      'فعالیت‌های روزانه مشاور',
      action: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          IconButton(
            onPressed:
            _previousMonth,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
            tooltip: 'ماه قبل',
          ),
          TextButton(
            onPressed: _goToday,
            child:
            const Text('امروز'),
          ),
          IconButton(
            onPressed:
            _nextMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
            tooltip: 'ماه بعد',
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthName(_month.month)} ${_fa(_month.year)}',
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddEventDialog(
                    context,
                    initialDate:
                    Jalali(
                      _month.year,
                      _month.month,
                      1,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text(
                  'فعالیت جدید',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              _WeekDay(
                text: 'شنبه',
              ),
              _WeekDay(
                text: 'یکشنبه',
              ),
              _WeekDay(
                text: 'دوشنبه',
              ),
              _WeekDay(
                text: 'سه‌شنبه',
              ),
              _WeekDay(
                text: 'چهارشنبه',
              ),
              _WeekDay(
                text: 'پنجشنبه',
              ),
              _WeekDay(
                text: 'جمعه',
              ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1.15,
            ),
            itemBuilder:
                (context, index) {
              final day =
                  index - firstWeekDay + 1;

              if (day < 1 ||
                  day > days) {
                return const SizedBox();
              }

              final dayEvents =
              _eventsForDay(day);

              final today =
              Jalali.fromDateTime(
                DateTime.now(),
              );

              final isToday =
                  today.year ==
                      _month.year &&
                      today.month ==
                          _month.month &&
                      today.day == day;

              return _CalendarDay(
                day: day,
                events: dayEvents,
                isToday: isToday,
                onTap: () {
                  _showDayEvents(
                    context,
                    day,
                    dayEvents,
                  );
                },
                onAdd: () {
                  _showAddEventDialog(
                    context,
                    initialDate:
                    Jalali(
                      _month.year,
                      _month.month,
                      day,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDayEvents(
      BuildContext context,
      int day,
      List<ConsultantEvent> events,
      ) async {
    if (events.isEmpty) {
      await _showAddEventDialog(
        context,
        initialDate: Jalali(
          _month.year,
          _month.month,
          day,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'فعالیت‌های ${_fa(day)} ${_monthName(_month.month)}',
            ),
            content: SizedBox(
              width: 430,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder:
                    (_, __) =>
                const Divider(),
                itemBuilder:
                    (context, index) {
                  final event =
                  events[index];

                  return ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading:
                    _EventStatusIcon(
                      event: event,
                    ),
                    title: Text(
                      event.title,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    subtitle:
                    Text(
                      _eventTime(event),
                    ),
                    trailing:
                    PopupMenuButton(
                      itemBuilder:
                          (context) => [
                        const PopupMenuItem(
                          value: 'complete',
                          child: Text(
                            'انجام شد',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'حذف',
                          ),
                        ),
                      ],
                      onSelected:
                          (value) async {
                        if (value ==
                            'complete') {
                          await _completeEvent(
                            event,
                          );
                        }

                        if (value ==
                            'delete') {
                          await _deleteEvent(
                            event,
                          );
                        }

                        if (context
                            .mounted) {
                          Navigator.pop(
                            context,
                          );
                        }

                        widget.onRefresh();
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                    ),
                child:
                const Text('بستن'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(
                    context,
                  );

                  await _showAddEventDialog(
                    context,
                    initialDate:
                    Jalali(
                      _month.year,
                      _month.month,
                      day,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label:
                const Text(
                  'فعالیت جدید',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddEventDialog(
      BuildContext context, {
        required Jalali initialDate,
      }) async {
    final result =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return _AddEventDialog(
          initialDate: initialDate,
        );
      },
    );

    if (result == true) {
      widget.onRefresh();
    }
  }

  Future<void> _completeEvent(
      ConsultantEvent event,
      ) async {
    await Supabase.instance.client
        .from('consultant_events')
        .update({
      'status': 'completed',
      'updated_at':
      DateTime.now()
          .toIso8601String(),
    }).eq(
      'id',
      event.id,
    );
  }

  Future<void> _deleteEvent(
      ConsultantEvent event,
      ) async {
    await Supabase.instance.client
        .from('consultant_events')
        .delete()
        .eq(
      'id',
      event.id,
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String text;

  const _WeekDay({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight:
            FontWeight.w700,
            color:
            Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final List<ConsultantEvent> events;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _CalendarDay({
    required this.day,
    required this.events,
    required this.isToday,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvents =
        events.isNotEmpty;

    final tooltip = hasEvents
        ? events
        .map(
          (event) =>
      '• ${event.title}${event.companyName == null ? '' : ' - ${event.companyName}'}',
    )
        .join('\n')
        : 'بدون فعالیت';

    return Tooltip(
      message: tooltip,
      waitDuration:
      const Duration(
        milliseconds: 250,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onAdd,
          borderRadius:
          BorderRadius.circular(10),
          child: Container(
            padding:
            const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(
                0xFF1B4332,
              )
                  : hasEvents
                  ? const Color(
                0xFF1B4332,
              ).withOpacity(.06)
                  : const Color(
                0xFFF8FAFC,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color: isToday
                    ? const Color(
                  0xFF1B4332,
                )
                    : const Color(
                  0xFFE2E8F0,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  _fa(day),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w800,
                    color: isToday
                        ? Colors.white
                        : const Color(
                      0xFF0F172A,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (hasEvents)
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration:
                        BoxDecoration(
                          shape:
                          BoxShape.circle,
                          color: isToday
                              ? Colors.white
                              : const Color(
                            0xFFF97316,
                          ),
                        ),
                      ),
                      if (events.length > 1) ...[
                        const SizedBox(
                          width: 3,
                        ),
                        Text(
                          _fa(events.length),
                          style:
                          TextStyle(
                            fontSize: 8,
                            fontWeight:
                            FontWeight.w800,
                            color: isToday
                                ? Colors.white
                                : const Color(
                              0xFFF97316,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* NOTES                                                                      */
/* -------------------------------------------------------------------------- */

class _NotesCard extends StatelessWidget {
  final List<ConsultantNote> notes;
  final VoidCallback onRefresh;

  const _NotesCard({
    required this.notes,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final visible =
    notes.take(6).toList();

    return _DashboardCard(
      title: 'یادداشت‌های من',
      subtitle:
      'یادداشت‌های شخصی مشاور',
      action: ElevatedButton.icon(
        onPressed: () async {
          final result =
          await showDialog<bool>(
            context: context,
            builder: (_) =>
            const _NoteDialog(),
          );

          if (result == true) {
            onRefresh();
          }
        },
        icon: const Icon(
          Icons.add_rounded,
          size: 17,
        ),
        label:
        const Text('یادداشت جدید'),
      ),
      child: visible.isEmpty
          ? const SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .sticky_note_2_outlined,
                size: 38,
                color:
                Color(0xFFCBD5E1),
              ),
              SizedBox(height: 10),
              Text(
                'هنوز یادداشتی ثبت نشده است',
                style: TextStyle(
                  fontSize: 11,
                  color:
                  Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          ...visible.map(
                (note) => _NoteItem(
              note: note,
              onRefresh:
              onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final ConsultantNote note;
  final VoidCallback onRefresh;

  const _NoteItem({
    required this.note,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
      const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: note.isPinned
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF8FAFC),
        borderRadius:
        BorderRadius.circular(13),
        border: Border.all(
          color: note.isPinned
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            note.isPinned
                ? Icons.push_pin_rounded
                : Icons
                .sticky_note_2_rounded,
            size: 19,
            color: note.isPinned
                ? const Color(0xFFD97706)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 19,
            onSelected:
                (value) async {
              if (value == 'edit') {
                final result =
                await showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      _NoteDialog(
                        note: note,
                      ),
                );

                if (result == true) {
                  onRefresh();
                }
              }

              if (value == 'pin') {
                await Supabase
                    .instance.client
                    .from(
                  'consultant_notes',
                )
                    .update({
                  'is_pinned':
                  !note.isPinned,
                  'updated_at':
                  DateTime.now()
                      .toIso8601String(),
                }).eq(
                  'id',
                  note.id,
                );

                onRefresh();
              }

              if (value == 'delete') {
                await Supabase
                    .instance.client
                    .from(
                  'consultant_notes',
                )
                    .delete()
                    .eq(
                  'id',
                  note.id,
                );

                onRefresh();
              }
            },
            itemBuilder:
                (context) => [
              const PopupMenuItem(
                value: 'edit',
                child:
                Text('ویرایش'),
              ),
              PopupMenuItem(
                value: 'pin',
                child: Text(
                  note.isPinned
                      ? 'برداشتن سنجاق'
                      : 'سنجاق کردن',
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child:
                Text('حذف'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* NOTE DIALOG                                                                */
/* -------------------------------------------------------------------------- */

class _NoteDialog extends StatefulWidget {
  final ConsultantNote? note;

  const _NoteDialog({
    this.note,
  });

  @override
  State<_NoteDialog> createState() =>
      _NoteDialogState();
}

class _NoteDialogState
    extends State<_NoteDialog> {
  late final TextEditingController
  _titleController;

  late final TextEditingController
  _contentController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(
          text: widget.note?.title ?? '',
        );

    _contentController =
        TextEditingController(
          text: widget.note?.content ?? '',
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title =
    _titleController.text.trim();

    final content =
    _contentController.text.trim();

    if (title.isEmpty) {
      _message(
        'عنوان یادداشت را وارد کنید.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final client =
          Supabase.instance.client;

      final userId =
          client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(
          'کاربر وارد سیستم نشده است.',
        );
      }

      if (widget.note == null) {
        await client
            .from('consultant_notes')
            .insert({
          'consultant_user_id':
          userId,
          'title': title,
          'content': content,
        });
      } else {
        await client
            .from('consultant_notes')
            .update({
          'title': title,
          'content': content,
          'updated_at':
          DateTime.now()
              .toIso8601String(),
        }).eq(
          'id',
          widget.note!.id,
        );
      }

      if (mounted) {
        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
        });

        _message(
          'خطا در ذخیره یادداشت\n$e',
        );
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.note == null
              ? 'یادداشت جدید'
              : 'ویرایش یادداشت',
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              TextField(
                controller:
                _titleController,
                decoration:
                const InputDecoration(
                  labelText:
                  'عنوان',
                  hintText:
                  'مثلاً پیگیری جلسه',
                  border:
                  OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              TextField(
                controller:
                _contentController,
                minLines: 5,
                maxLines: 9,
                decoration:
                const InputDecoration(
                  labelText:
                  'متن یادداشت',
                  hintText:
                  'یادداشت خود را بنویسید...',
                  border:
                  OutlineInputBorder(),
                  alignLabelWithHint:
                  true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () =>
                Navigator.pop(
                  context,
                ),
            child:
            const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed:
            _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text(
              'ذخیره',
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ADD EVENT DIALOG                                                           */
/* -------------------------------------------------------------------------- */

class _AddEventDialog
    extends StatefulWidget {
  final Jalali initialDate;

  const _AddEventDialog({
    required this.initialDate,
  });

  @override
  State<_AddEventDialog> createState() =>
      _AddEventDialogState();
}

class _AddEventDialogState
    extends State<_AddEventDialog> {
  late Jalali _date;

  final _titleController =
  TextEditingController();

  final _descriptionController =
  TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _allDay = false;
  bool _saving = false;

  String _priority = 'normal';
  String? _companyId;

  List<ConsultantCompany>
  _companies = [];

  @override
  void initState() {
    super.initState();

    _date = widget.initialDate;

    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final client =
        Supabase.instance.client;

    final userId =
        client.auth.currentUser?.id;

    if (userId == null) return;

    try {
      final response =
      await client
          .from(
        'consultant_company_assignments',
      )
          .select(
        'company_id, companies(id,name)',
      )
          .eq(
        'consultant_user_id',
        userId,
      )
          .eq(
        'is_active',
        true,
      );

      final rows =
      List<Map<String, dynamic>>.from(
        response,
      );

      final list =
      <ConsultantCompany>[];

      for (final row in rows) {
        final company =
        row['companies'];

        if (company is Map) {
          list.add(
            ConsultantCompany(
              id: company['id']
                  .toString(),
              name:
              company['name']
                  ?.toString() ??
                  '',
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _companies = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result =
    await showDialog<Jalali>(
      context: context,
      builder: (_) =>
          _JalaliDatePickerDialog(
            initialDate: _date,
          ),
    );

    if (result != null) {
      setState(() {
        _date = result;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final result =
    await showTimePicker(
      context: context,
      initialTime:
      _startTime ??
          const TimeOfDay(
            hour: 9,
            minute: 0,
          ),
    );

    if (result != null) {
      setState(() {
        _startTime = result;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final result =
    await showTimePicker(
      context: context,
      initialTime:
      _endTime ??
          const TimeOfDay(
            hour: 10,
            minute: 0,
          ),
    );

    if (result != null) {
      setState(() {
        _endTime = result;
      });
    }
  }

  Future<void> _save() async {
    final title =
    _titleController.text.trim();

    if (title.isEmpty) {
      _message(
        'عنوان فعالیت را وارد کنید.',
      );
      return;
    }

    if (!_allDay &&
        _startTime != null &&
        _endTime != null) {
      final start =
          _startTime!.hour * 60 +
              _startTime!.minute;

      final end =
          _endTime!.hour * 60 +
              _endTime!.minute;

      if (end <= start) {
        _message(
          'ساعت پایان باید بعد از ساعت شروع باشد.',
        );
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      final client =
          Supabase.instance.client;

      final userId =
          client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(
          'کاربر وارد سیستم نشده است.',
        );
      }

      final eventDate =
      _date
          .toDateTime();

      await client
          .from('consultant_events')
          .insert({
        'consultant_user_id':
        userId,
        'company_id':
        _companyId,
        'title': title,
        'description':
        _descriptionController
            .text
            .trim(),
        'event_date':
        _dateToDb(eventDate),
        'start_time':
        _allDay ||
            _startTime == null
            ? null
            : _timeToDb(
          _startTime!,
        ),
        'end_time':
        _allDay ||
            _endTime == null
            ? null
            : _timeToDb(
          _endTime!,
        ),
        'is_all_day':
        _allDay,
        'status': 'pending',
        'priority':
        _priority,
      });

      if (mounted) {
        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
        });

        _message(
          'خطا در ثبت فعالیت\n$e',
        );
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          'فعالیت جدید',
        ),
        content: SizedBox(
          width: 470,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                TextField(
                  controller:
                  _titleController,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'عنوان فعالیت',
                    hintText:
                    'مثلاً جلسه بررسی گزارش مالی',
                    border:
                    OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller:
                  _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'توضیحات',
                    border:
                    OutlineInputBorder(),
                    alignLabelWithHint:
                    true,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                InkWell(
                  onTap: _pickDate,
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                  child: InputDecorator(
                    decoration:
                    const InputDecoration(
                      labelText:
                      'تاریخ',
                      border:
                      OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .calendar_month_rounded,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          '${_fa(_date.day)} ${_monthName(_date.month)} ${_fa(_date.year)}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                SwitchListTile(
                  contentPadding:
                  EdgeInsets.zero,
                  title:
                  const Text(
                    'تمام روز',
                  ),
                  value: _allDay,
                  onChanged: (value) {
                    setState(() {
                      _allDay = value;
                    });
                  },
                ),

                if (!_allDay) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                        OutlinedButton.icon(
                          onPressed:
                          _pickStartTime,
                          icon:
                          const Icon(
                            Icons
                                .schedule_rounded,
                            size: 18,
                          ),
                          label:
                          Text(
                            _startTime ==
                                null
                                ? 'ساعت شروع'
                                : _timeLabel(
                              _startTime!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                        OutlinedButton.icon(
                          onPressed:
                          _pickEndTime,
                          icon:
                          const Icon(
                            Icons
                                .schedule_rounded,
                            size: 18,
                          ),
                          label:
                          Text(
                            _endTime ==
                                null
                                ? 'ساعت پایان'
                                : _timeLabel(
                              _endTime!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(
                  height: 12,
                ),

                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'اولویت',
                    border:
                    OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'low',
                      child:
                      Text('کم'),
                    ),
                    DropdownMenuItem(
                      value: 'normal',
                      child:
                      Text('عادی'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child:
                      Text('زیاد'),
                    ),
                  ],
                  onChanged:
                      (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _priority =
                          value;
                    });
                  },
                ),

                const SizedBox(
                  height: 12,
                ),

                DropdownButtonFormField<String?>(
                  value: _companyId,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'شرکت مرتبط',
                    hintText:
                    'اختیاری',
                    border:
                    OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<
                        String?>(
                      value: null,
                      child:
                      Text(
                        'بدون شرکت',
                      ),
                    ),
                    ..._companies.map(
                          (company) =>
                          DropdownMenuItem<
                              String?>(
                            value:
                            company.id,
                            child:
                            Text(
                              company.name,
                            ),
                          ),
                    ),
                  ],
                  onChanged:
                      (value) {
                    setState(() {
                      _companyId =
                          value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () =>
                Navigator.pop(
                  context,
                ),
            child:
            const Text('انصراف'),
          ),
          ElevatedButton.icon(
            onPressed:
            _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
              width: 16,
              height: 16,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.save_rounded,
              size: 18,
            ),
            label:
            const Text('ثبت فعالیت'),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* JALALI DATE PICKER                                                         */
/* -------------------------------------------------------------------------- */

class _JalaliDatePickerDialog
    extends StatefulWidget {
  final Jalali initialDate;

  const _JalaliDatePickerDialog({
    required this.initialDate,
  });

  @override
  State<_JalaliDatePickerDialog>
  createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState
    extends State<
        _JalaliDatePickerDialog> {
  late Jalali _month;

  @override
  void initState() {
    super.initState();

    _month = Jalali(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
  }

  int _daysInMonth() {
    final first =
    _month.toDateTime();

    final next =
    _month.month == 12
        ? Jalali(
      _month.year + 1,
      1,
      1,
    ).toDateTime()
        : Jalali(
      _month.year,
      _month.month + 1,
      1,
    ).toDateTime();

    return next
        .difference(first)
        .inDays;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay =
    Jalali(
      _month.year,
      _month.month,
      1,
    );

    final firstWeekDay =
        (firstDay.weekDay + 1) % 7;

    final days =
    _daysInMonth();

    final cells =
        ((firstWeekDay + days + 6) ~/ 7) *
            7;

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  if (_month.month ==
                      1) {
                    _month = Jalali(
                      _month.year - 1,
                      12,
                      1,
                    );
                  } else {
                    _month = Jalali(
                      _month.year,
                      _month.month - 1,
                      1,
                    );
                  }
                });
              },
              icon: const Icon(
                Icons
                    .chevron_right_rounded,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_monthName(_month.month)} ${_fa(_month.year)}',
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  if (_month.month ==
                      12) {
                    _month = Jalali(
                      _month.year + 1,
                      1,
                      1,
                    );
                  } else {
                    _month = Jalali(
                      _month.year,
                      _month.month + 1,
                      1,
                    );
                  }
                });
              },
              icon: const Icon(
                Icons
                    .chevron_left_rounded,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 390,
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Row(
                children: const [
                  _WeekDay(
                    text: 'ش',
                  ),
                  _WeekDay(
                    text: 'ی',
                  ),
                  _WeekDay(
                    text: 'د',
                  ),
                  _WeekDay(
                    text: 'س',
                  ),
                  _WeekDay(
                    text: 'چ',
                  ),
                  _WeekDay(
                    text: 'پ',
                  ),
                  _WeekDay(
                    text: 'ج',
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              GridView.builder(
                shrinkWrap: true,
                itemCount: cells,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemBuilder:
                    (context, index) {
                  final day =
                      index -
                          firstWeekDay +
                          1;

                  if (day < 1 ||
                      day > days) {
                    return const SizedBox();
                  }

                  final selected =
                      day ==
                          widget
                              .initialDate
                              .day &&
                          _month.year ==
                              widget
                                  .initialDate
                                  .year &&
                          _month.month ==
                              widget
                                  .initialDate
                                  .month;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(
                        context,
                        Jalali(
                          _month.year,
                          _month.month,
                          day,
                        ),
                      );
                    },
                    borderRadius:
                    BorderRadius.circular(
                      9,
                    ),
                    child: Container(
                      decoration:
                      BoxDecoration(
                        color: selected
                            ? const Color(
                          0xFF1B4332,
                        )
                            : const Color(
                          0xFFF8FAFC,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          9,
                        ),
                      ),
                      alignment:
                      Alignment.center,
                      child: Text(
                        _fa(day),
                        style:
                        TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : const Color(
                            0xFF0F172A,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
                  context,
                ),
            child:
            const Text('انصراف'),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EVENTS TABLE                                                               */
/* -------------------------------------------------------------------------- */

class _EventsSection extends StatelessWidget {
  final List<ConsultantEvent> events;
  final VoidCallback onRefresh;

  const _EventsSection({
    required this.events,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final sorted =
    [...events]
      ..sort(
            (a, b) => a.eventDate.compareTo(
          b.eventDate,
        ),
      );

    final visible =
    sorted.take(12).toList();

    return _DashboardCard(
      title: 'فعالیت‌های من',
      subtitle:
      'تمام فعالیت‌های تعریف‌شده در تقویم',
      child: visible.isEmpty
          ? const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'هنوز فعالیتی ثبت نشده است.',
            style: TextStyle(
              fontSize: 11,
              color:
              Color(0xFF94A3B8),
            ),
          ),
        ),
      )
          : LayoutBuilder(
        builder:
            (context, constraints) {
          if (constraints.maxWidth <
              700) {
            return Column(
              children: visible
                  .map(
                    (event) =>
                    _MobileEventRow(
                      event: event,
                      onRefresh:
                      onRefresh,
                    ),
              )
                  .toList(),
            );
          }

          return Column(
            children: [
              _EventTableHeader(),
              const SizedBox(
                height: 6,
              ),
              ...visible.map(
                    (event) =>
                    _EventTableRow(
                      event: event,
                      onRefresh:
                      onRefresh,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventTableHeader
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF1F5F9),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'تاریخ',
              style: _TableHeaderStyle.style,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'ساعت',
              style: _TableHeaderStyle.style,
            ),
          ),
          Expanded(
            child: Text(
              'عنوان فعالیت',
              style: _TableHeaderStyle.style,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'شرکت',
              style: _TableHeaderStyle.style,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'وضعیت',
              style: _TableHeaderStyle.style,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderStyle {
  static const style = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: Color(0xFF64748B),
  );
}

class _EventTableRow
    extends StatelessWidget {
  final ConsultantEvent event;
  final VoidCallback onRefresh;

  const _EventTableRow({
    required this.event,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final j =
    Jalali.fromDateTime(
      event.eventDate,
    );

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
            Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '${_fa(j.day)} ${_monthName(j.month)}',
              style:
              const TextStyle(
                fontSize: 10,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              _eventTime(event),
              style:
              const TextStyle(
                fontSize: 10,
                color:
                Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              event.title,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              event.companyName ??
                  'شخصی',
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                fontSize: 10,
                color:
                Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: _StatusBadge(
              status:
              event.status,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileEventRow
    extends StatelessWidget {
  final ConsultantEvent event;
  final VoidCallback onRefresh;

  const _MobileEventRow({
    required this.event,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final j =
    Jalali.fromDateTime(
      event.eventDate,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
      const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF8FAFC),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _EventStatusIcon(
            event: event,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_fa(j.day)} ${_monthName(j.month)} • ${_eventTime(event)}',
                  style:
                  const TextStyle(
                    fontSize: 9,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
                if (event.companyName !=
                    null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.companyName!,
                    style:
                    const TextStyle(
                      fontSize: 9,
                      color:
                      Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _StatusBadge(
            status:
            event.status,
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COMPANY COMPARISON                                                         */
/* -------------------------------------------------------------------------- */

class _CompanyComparison
    extends StatelessWidget {
  final List<ConsultantCompany>
  companies;

  const _CompanyComparison({
    required this.companies,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'شرکت‌های تحت پوشش',
      subtitle:
      'نمای کلی شرکت‌هایی که تحت مدیریت شما هستند',
      child: companies.isEmpty
          ? const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'شرکتی برای نمایش وجود ندارد.',
            style: TextStyle(
              fontSize: 11,
              color:
              Color(0xFF94A3B8),
            ),
          ),
        ),
      )
          : LayoutBuilder(
        builder:
            (context, constraints) {
          final count =
          constraints.maxWidth >=
              1000
              ? 3
              : constraints.maxWidth >=
              600
              ? 2
              : 1;

          const gap = 10.0;

          final width =
          count == 1
              ? constraints.maxWidth
              : (constraints.maxWidth -
              ((count - 1) *
                  gap)) /
              count;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children:
            companies.map(
                  (company) {
                return SizedBox(
                  width: width,
                  child:
                  _CompanyItem(
                    company:
                    company,
                  ),
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }
}

class _CompanyItem
    extends StatelessWidget {
  final ConsultantCompany company;

  const _CompanyItem({
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF8FAFC),
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFF1B4332,
              ).withOpacity(.09),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child:
            const Icon(
              Icons
                  .business_rounded,
              size: 21,
              color:
              Color(0xFF1B4332),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              company.name,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons
                .chevron_left_rounded,
            size: 20,
            color:
            Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COMMON CARD                                                                */
/* -------------------------------------------------------------------------- */

class _DashboardCard
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        Color(
                          0xFF0F172A,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        fontSize: 10,
                        color:
                        Color(
                          0xFF64748B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(
                  width: 10,
                ),
                action!,
              ],
            ],
          ),
          const SizedBox(
            height: 17,
          ),
          child,
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* STATUS                                                                     */
/* -------------------------------------------------------------------------- */

class _StatusBadge
    extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final completed =
        status == 'completed';

    final cancelled =
        status == 'cancelled';

    final text = completed
        ? 'انجام شد'
        : cancelled
        ? 'لغو شد'
        : 'در انتظار';

    final color = completed
        ? const Color(0xFF16A34A)
        : cancelled
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(.09),
        borderRadius:
        BorderRadius.circular(
          8,
        ),
      ),
      child: Text(
        text,
        textAlign:
        TextAlign.center,
        style:
        TextStyle(
          fontSize: 8,
          fontWeight:
          FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EventStatusIcon
    extends StatelessWidget {
  final ConsultantEvent event;

  const _EventStatusIcon({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    event.status == 'completed'
        ? const Color(0xFF16A34A)
        : event.priority == 'high'
        ? const Color(
      0xFFDC2626,
    )
        : const Color(
      0xFFF97316,
    );

    return Container(
      width: 40,
      height: 40,
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(.10),
        borderRadius:
        BorderRadius.circular(
          11,
        ),
      ),
      child: Icon(
        event.status ==
            'completed'
            ? Icons
            .check_circle_rounded
            : Icons
            .event_note_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ERROR                                                                      */
/* -------------------------------------------------------------------------- */

class _ErrorView
    extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Container(
          constraints:
          const BoxConstraints(
            maxWidth: 550,
          ),
          padding:
          const EdgeInsets.all(24),
          decoration:
          BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
              const Color(
                0xFFE2E8F0,
              ),
            ),
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                size: 50,
                color:
                Color(0xFFDC2626),
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'خطا در دریافت داشبورد مشاور',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                error.toString(),
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 10,
                  color:
                  Color(0xFF64748B),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons
                      .refresh_rounded,
                ),
                label:
                const Text(
                  'تلاش مجدد',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HELPERS                                                                    */
/* -------------------------------------------------------------------------- */

String _fa(int value) {
  return value
      .toString()
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹');
}

String _monthName(int month) {
  const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  if (month < 1 ||
      month > 12) {
    return '';
  }

  return months[month - 1];
}

String _eventTime(
    ConsultantEvent event,
    ) {
  if (event.isAllDay) {
    return 'تمام روز';
  }

  if (event.startTime == null) {
    return 'بدون ساعت';
  }

  final start =
  _dbTimeToPersian(
    event.startTime!,
  );

  if (event.endTime == null) {
    return start;
  }

  return '$start تا ${_dbTimeToPersian(event.endTime!)}';
}

String _dbTimeToPersian(
    String value,
    ) {
  final parts =
  value.split(':');

  if (parts.length < 2) {
    return value;
  }

  final hour =
      int.tryParse(parts[0]) ?? 0;

  final minute =
      int.tryParse(parts[1]) ?? 0;

  return '${_fa(hour)}:${_fa(minute).padLeft(2, '۰')}';
}

String _timeLabel(
    TimeOfDay time,
    ) {
  return '${_fa(time.hour)}:${_fa(time.minute).padLeft(2, '۰')}';
}

String _timeToDb(
    TimeOfDay time,
    ) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
}

String _dateToDb(
    DateTime date,
    ) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}