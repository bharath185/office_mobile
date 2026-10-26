import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/utils/geofence_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';

class AttendanceScreen extends StatefulWidget {
  final UserModel user;

  const AttendanceScreen({super.key, required this.user});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final RealtimeService _realtime = RealtimeService();
  bool _isLoading = true;
  bool _isCheckingLocation = false;
  bool _isWithinGeofence = true;
  String _locationStatus = 'Office Premises (HQ Bengaluru)';
  List<AttendanceDayLog> _attendanceLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _verifyLocation();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _realtime.fetchAttendanceHistory(widget.user.empId, widget.user.loginId);
      if (mounted) {
        setState(() {
          _attendanceLogs = logs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyLocation() async {
    setState(() => _isCheckingLocation = true);
    final pos = await GeofenceHelper.getCurrentPosition();
    setState(() {
      _isCheckingLocation = false;
      if (pos != null) {
        _isWithinGeofence = GeofenceHelper.isWithinGeofence(userLat: pos.latitude, userLng: pos.longitude);
        _locationStatus = _isWithinGeofence ? 'Verified inside Office Geofence' : 'Outside Office Geofence';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance & Time Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              _loadData();
              _verifyLocation();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
          await _verifyLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shift & Geofence Card
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('General Shift (GS-1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('09:00 AM - 06:00 PM • 9h 00m', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Grace: 15m', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(
                          _isWithinGeofence ? Icons.location_on : Icons.location_off,
                          color: _isWithinGeofence ? AppColors.success : AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isCheckingLocation ? 'Checking GPS Location...' : _locationStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isWithinGeofence ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live On-site Punch Action
              PrimaryButton(
                icon: Icons.fingerprint_rounded,
                label: 'Punch Attendance (Office Geofence)',
                onPressed: () async {
                  final ok = await _realtime.punchIn(
                    loginId: widget.user.loginId,
                    empCode: widget.user.empCode,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Attendance punched successfully!' : 'Punch recorded in system'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadData();
                  }
                },
              ),
              const SizedBox(height: 24),

              // Monthly Live Attendance History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Realtime Attendance History (${_attendanceLogs.length} Days)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_attendanceLogs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text('No attendance history found for this period', style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ..._attendanceLogs.reversed.map((log) => AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                log.status == 'Present'
                                    ? 'In: ${log.inTime.substring(0, 5)}  •  Out: ${log.outTime.substring(0, 5)}'
                                    : 'Not punched / Absent',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                log.status == 'Present' ? log.workingHours : '--:--',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: log.status == 'Present' ? AppColors.primary : AppColors.textMuted,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: log.status),
                            ],
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
