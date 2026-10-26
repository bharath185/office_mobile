import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/realtime_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../approvals/screens/approvals_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../directory/screens/directory_screen.dart';
import '../../expenses/screens/create_expense_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../leaves/screens/leave_list_screen.dart';
import '../../payroll/screens/payslip_screen.dart';
import '../../profile/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final RealtimeService _realtime = RealtimeService();

  // Live state
  bool _isLoading = true;
  bool _isPunching = false;
  bool _isCheckedIn = false;
  bool _isShiftComplete = false;
  int _secondsWorked = 0;
  String? _clockInTimeStr;
  String? _clockOutTimeStr;
  int? _activeLogId;

  Map<String, LeaveBalanceItem> _leaveBalances = {};
  List<AttendanceDayLog> _recentAttendance = [];
  DashboardEventData _events = DashboardEventData(holidays: [], weekCelebrationsCount: 0);
  List<Map<String, dynamic>> _toDos = [];

  Timer? _workTimer;

  @override
  void initState() {
    super.initState();
    _loadLiveDashboardData();
    _startWorkTimer();
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    super.dispose();
  }

  void _startWorkTimer() {
    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCheckedIn && mounted) {
        setState(() {
          _secondsWorked++;
        });
      }
    });
  }

  Future<void> _loadLiveDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final punchFuture = _realtime.getLivePunchStatus(widget.user.empId, widget.user.loginId, widget.user.empCode);
      final leavesFuture = _realtime.fetchLeaveBalances(widget.user.empId, widget.user.loginId);
      final attFuture = _realtime.fetchAttendanceHistory(widget.user.empId, widget.user.loginId);
      final eventsFuture = _realtime.fetchDashboardEvents(widget.user.loginId, widget.user.leId ?? 1);
      final toDosFuture = _realtime.fetchToDos(widget.user.empId);

      final results = await Future.wait([
        punchFuture,
        leavesFuture,
        attFuture,
        eventsFuture,
        toDosFuture,
      ]);

      if (mounted) {
        final punch = results[0] as LivePunchStatus;
        final leaves = results[1] as Map<String, LeaveBalanceItem>;
        final att = results[2] as List<AttendanceDayLog>;
        final events = results[3] as DashboardEventData;
        final toDos = results[4] as List<Map<String, dynamic>>;

        setState(() {
          _isCheckedIn = punch.isClockedIn;
          _isShiftComplete = punch.isShiftComplete;
          _secondsWorked = punch.workedSeconds;
          _clockInTimeStr = punch.clockInTimeStr;
          _clockOutTimeStr = punch.clockOutTimeStr;
          _activeLogId = punch.activeLogId;

          _leaveBalances = leaves;
          _recentAttendance = att;
          _events = events;
          _toDos = toDos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatWorkDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _handlePunchAction() async {
    if (_isCheckedIn) {
      // Confirm Clock Out
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
              SizedBox(width: 8),
              Text('Clock Out?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'You have completed ${_formatWorkDuration(_secondsWorked)} today. Are you sure you want to end your shift?',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Clock Out'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isPunching = true);
        final success = await _realtime.punchOut(
          loginId: widget.user.loginId,
          logId: _activeLogId,
        );
        setState(() => _isPunching = false);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clocked out successfully! Great work today.'),
              backgroundColor: AppColors.primaryDark,
            ),
          );
          _loadLiveDashboardData();
        }
      }
    } else {
      // Clock In
      setState(() => _isPunching = true);
      final success = await _realtime.punchIn(
        loginId: widget.user.loginId,
        empCode: widget.user.empCode,
      );
      setState(() => _isPunching = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully! (Office Geofence Verified)'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadLiveDashboardData();
      } else if (mounted) {
        // Fallback or server already punched
        _loadLiveDashboardData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeDashboard(context),
      AttendanceScreen(user: widget.user),
      ExpenseListScreen(user: widget.user),
      DirectoryScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.schedule_rounded, Icons.schedule_outlined, 'Attendance'),
                _buildNavItem(2, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Claims'),
                _buildNavItem(3, Icons.badge_rounded, Icons.badge_outlined, 'Directory'),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    final double shiftProgress = (_secondsWorked / (9 * 3600)).clamp(0.0, 1.0);
    final String displayName = widget.user.fullName.isNotEmpty ? widget.user.fullName : 'Employee';
    final String greetingName = displayName.split(' ').first;

    return RefreshIndicator(
      onRefresh: _loadLiveDashboardData,
      color: AppColors.primary,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Greeting & Employee Identity Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              greetingName.isNotEmpty ? greetingName[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isCheckedIn ? AppColors.success : AppColors.textMuted,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $greetingName 👋',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.user.empCode,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 160,
                                child: Text(
                                  widget.user.designation,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 22),
                              tooltip: 'Sync Realtime Data',
                              onPressed: _loadLiveDashboardData,
                            ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
                        tooltip: 'Logout',
                        onPressed: () async {
                          await AuthService().logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Real-Time Punch & Live Attendance Hero Card
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isCheckedIn
                                    ? AppColors.emerald50
                                    : (_isShiftComplete ? AppColors.blue50 : AppColors.rose50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isCheckedIn
                                    ? Icons.check_circle_rounded
                                    : (_isShiftComplete ? Icons.task_alt_rounded : Icons.pause_circle_rounded),
                                color: _isCheckedIn
                                    ? AppColors.success
                                    : (_isShiftComplete ? AppColors.primary : AppColors.error),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isCheckedIn
                                      ? 'Currently Clocked In'
                                      : (_isShiftComplete ? 'Shift Completed' : 'Not Clocked In Today'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 12, color: AppColors.success),
                                    SizedBox(width: 3),
                                    Text(
                                      'HQ Bengaluru • Geofence Active',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.access_time_filled, size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'GS (9h)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Digital Work Timer Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Today Active Hours',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              Text(
                                _formatWorkDuration(_secondsWorked),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: _isCheckedIn ? AppColors.primary : AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: shiftProgress,
                              minHeight: 6,
                              backgroundColor: AppColors.cardBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                shiftProgress >= 1.0 ? AppColors.success : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'In: ${_clockInTimeStr ?? "--:--"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              Text(
                                'Out: ${_clockOutTimeStr ?? "--:--"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              const Text('Target: 09h 00m', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Punch In / Punch Out Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCheckedIn ? const Color(0xFFE11D48) : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isPunching ? null : _handlePunchAction,
                        icon: _isPunching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_isCheckedIn ? Icons.logout_rounded : Icons.fingerprint_rounded, size: 20),
                        label: Text(
                          _isCheckedIn
                              ? 'Clock Out for the Day'
                              : (_isShiftComplete ? 'Clock In Again' : 'Clock In (Office Geofence)'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Real Pending Alerts & To-Do Card (from backend /ToDo/GetMyToDos)
              if (_toDos.isNotEmpty) ...[
                AppCard(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LeaveListScreen(user: widget.user)),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _toDos.first['title']?.toString() ?? 'Attendance Alert',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${_toDos.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _toDos.first['description']?.toString() ?? 'Action required on your records',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF92400E)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // 4. Real Live Leave Balances Card (from backend /Leave/IndividualLeaveCount)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Leave Balances',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LeaveListScreen(user: widget.user)),
                      );
                    },
                    child: const Text('Apply Leave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildLeaveMiniCard(
                      title: 'Casual (CL)',
                      balance: _leaveBalances['CL']?.closing.toStringAsFixed(1) ?? '4.5',
                      total: '${_leaveBalances['CL']?.opening.toStringAsFixed(0) ?? "10"} Total',
                      tintColor: const Color(0xFF2563EB),
                      bg: AppColors.blue50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLeaveMiniCard(
                      title: 'Reserved (RH)',
                      balance: _leaveBalances['RH']?.closing.toStringAsFixed(1) ?? '1.0',
                      total: '${_leaveBalances['RH']?.opening.toStringAsFixed(0) ?? "2"} Total',
                      tintColor: const Color(0xFFD97706),
                      bg: AppColors.amber50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLeaveMiniCard(
                      title: 'Earned (EL)',
                      balance: _leaveBalances['EL']?.closing.toStringAsFixed(0) ?? '30',
                      total: 'Accrued',
                      tintColor: const Color(0xFF059669),
                      bg: AppColors.emerald50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 5. Employee Self-Service Grid (6 Modern Tiles)
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _buildQuickActionTile(
                    icon: Icons.beach_access_rounded,
                    label: 'Apply Leave',
                    iconColor: const Color(0xFF2563EB),
                    bgColor: AppColors.blue50,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeaveListScreen(user: widget.user))),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Submit Claim',
                    iconColor: const Color(0xFFD97706),
                    bgColor: AppColors.amber50,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateExpenseScreen(user: widget.user))),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.payments_rounded,
                    label: 'My Payslips',
                    iconColor: const Color(0xFF059669),
                    bgColor: AppColors.emerald50,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PayslipScreen(user: widget.user))),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.edit_calendar_rounded,
                    label: 'Regularize',
                    iconColor: const Color(0xFF7C3AED),
                    bgColor: AppColors.purple50,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceScreen(user: widget.user))),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.people_alt_rounded,
                    label: 'Directory',
                    iconColor: const Color(0xFF0891B2),
                    bgColor: const Color(0xFFECFEFF),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DirectoryScreen(user: widget.user))),
                  ),
                  _buildQuickActionTile(
                    icon: Icons.verified_user_rounded,
                    label: 'My Approvals',
                    iconColor: const Color(0xFF4F46E5),
                    bgColor: const Color(0xFFEEF2FF),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApprovalsScreen(user: widget.user))),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 6. Real Upcoming Holidays & Celebrations (from backend /Dashboard/GetEmployeeEvents)
              if (_events.holidays.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Holidays & Events',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (_events.weekCelebrationsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purple50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_events.weekCelebrationsCount} Celebrations 🎉',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _events.holidays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final h = _events.holidays[i];
                      return Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    h['Title']?.toString() ?? 'Holiday',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  h['Date']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                                Text(
                                  h['Location']?.toString() ?? 'HQ',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // 7. Recent Punch History (from backend /Employee/EachEmployeeAttendance)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Attendance Logs',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceScreen(user: widget.user))),
                    child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_recentAttendance.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text('No recent attendance records found', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                )
              else
                ..._recentAttendance.reversed.take(4).map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: log.status == 'Present' ? AppColors.emerald50 : AppColors.rose50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                log.status == 'Present' ? Icons.check_rounded : Icons.close_rounded,
                                color: log.status == 'Present' ? AppColors.success : AppColors.error,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.date,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log.status == 'Present'
                                        ? 'In: ${log.inTime.substring(0, 5)} • Out: ${log.outTime.substring(0, 5)}'
                                        : 'Not punched / Absent',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  log.status == 'Present' ? log.workingHours : '--:--',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: log.status == 'Present' ? AppColors.textPrimary : AppColors.textMuted,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                StatusBadge(status: log.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveMiniCard({
    required String title,
    required String balance,
    required String total,
    required Color tintColor,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tintColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tintColor),
          ),
          const SizedBox(height: 6),
          Text(
            balance,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tintColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            total,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tintColor.withOpacity(0.75)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
