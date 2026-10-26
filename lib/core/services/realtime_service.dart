import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

class LeaveBalanceItem {
  final String type;
  final String shortName;
  final double opening;
  final double availed;
  final double closing;

  LeaveBalanceItem({
    required this.type,
    required this.shortName,
    required this.opening,
    required this.availed,
    required this.closing,
  });

  factory LeaveBalanceItem.fromJson(Map<String, dynamic> json, String defaultShort) {
    return LeaveBalanceItem(
      type: json['LeaveType'] ?? defaultShort,
      shortName: defaultShort,
      opening: (json['OpeningBalance'] as num?)?.toDouble() ?? 0.0,
      availed: (json['Availed'] as num?)?.toDouble() ?? 0.0,
      closing: (json['ClosingBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LivePunchStatus {
  final bool isClockedIn;
  final bool isShiftComplete;
  final String? clockInTimeStr;
  final String? clockOutTimeStr;
  final int workedSeconds;
  final int? activeLogId;

  LivePunchStatus({
    required this.isClockedIn,
    this.isShiftComplete = false,
    this.clockInTimeStr,
    this.clockOutTimeStr,
    this.workedSeconds = 0,
    this.activeLogId,
  });
}

class AttendanceDayLog {
  final String date;
  final String inTime;
  final String outTime;
  final String workingHours;
  final String status;

  AttendanceDayLog({
    required this.date,
    required this.inTime,
    required this.outTime,
    required this.workingHours,
    required this.status,
  });

  factory AttendanceDayLog.fromJson(Map<String, dynamic> json) {
    final list = json['lstofAttendance'] as List?;
    final first = (list != null && list.isNotEmpty) ? list[0] as Map<String, dynamic> : <String, dynamic>{};

    return AttendanceDayLog(
      date: json['AttendaceDate']?.toString() ?? '',
      inTime: first['LogInTime']?.toString() ?? '00:00:00',
      outTime: first['LogOutTime']?.toString() ?? '00:00:00',
      workingHours: first['WorkingHours']?.toString() ?? '00:00:00',
      status: first['AttendanceStatus']?.toString() ?? first['Status']?.toString() ?? 'Absent',
    );
  }
}

class DashboardEventData {
  final List<Map<String, dynamic>> holidays;
  final int weekCelebrationsCount;

  DashboardEventData({
    required this.holidays,
    required this.weekCelebrationsCount,
  });
}

class RealtimeService {
  final ApiClient _client = ApiClient();

  /// Fetches real live leave balances for the authenticated employee
  Future<Map<String, LeaveBalanceItem>> fetchLeaveBalances(int empId, int loginId) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.leaveBalances,
        data: {'EmpId': empId, 'LoginId': loginId},
      );

      final Map<String, LeaveBalanceItem> balances = {};
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;

        if (data['CasualCounts'] is List && (data['CasualCounts'] as List).isNotEmpty) {
          balances['CL'] = LeaveBalanceItem.fromJson(data['CasualCounts'][0], 'CL');
        }
        if (data['ReservedHolidayCounts'] is List && (data['ReservedHolidayCounts'] as List).isNotEmpty) {
          balances['RH'] = LeaveBalanceItem.fromJson(data['ReservedHolidayCounts'][0], 'RH');
        }
        if (data['EarnedLeaveCounts'] is List && (data['EarnedLeaveCounts'] as List).isNotEmpty) {
          balances['EL'] = LeaveBalanceItem.fromJson(data['EarnedLeaveCounts'][0], 'EL');
        }
        if (data['CompOffCounts'] is List && (data['CompOffCounts'] as List).isNotEmpty) {
          balances['COMP'] = LeaveBalanceItem.fromJson(data['CompOffCounts'][0], 'COMP');
        }
      }
      return balances;
    } catch (_) {
      return {};
    }
  }

  /// Fetches real attendance history logs
  Future<List<AttendanceDayLog>> fetchAttendanceHistory(int empId, int loginId) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.eachEmployeeAttendance,
        data: {'EmpId': empId, 'LoginId': loginId},
      );

      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((item) => AttendanceDayLog.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Calculates real-time punch status based on today's active logs and attendance
  Future<LivePunchStatus> getLivePunchStatus(int empId, int loginId, String empCode) async {
    try {
      // 1. Check active OnSite login log
      final logsRes = await _client.dio.post(
        ApiEndpoints.allLoginLogs,
        data: {},
      );

      int? activeLogId;
      DateTime? loginTime;

      if (logsRes.statusCode == 200 && logsRes.data is List) {
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        for (var item in logsRes.data) {
          if (item is Map) {
            final logEmpCode = item['EmpCode']?.toString().toUpperCase();
            final actionType = item['ActionType']?.toString().toUpperCase();
            final logDate = item['LoginDate']?.toString();

            if (logEmpCode == empCode.toUpperCase() && actionType == 'LOGIN') {
              if (logDate != null && logDate.contains(todayStr)) {
                activeLogId = item['Id'] as int?;
                final rawTime = item['LoginTime']?.toString();
                if (rawTime != null) {
                  loginTime = DateTime.tryParse(rawTime);
                }
                break;
              }
            }
          }
        }
      }

      if (activeLogId != null) {
        final now = DateTime.now();
        final elapsed = loginTime != null ? now.difference(loginTime).inSeconds : 0;
        return LivePunchStatus(
          isClockedIn: true,
          clockInTimeStr: loginTime != null ? "${loginTime.hour.toString().padLeft(2, '0')}:${loginTime.minute.toString().padLeft(2, '0')}" : "Active",
          workedSeconds: elapsed > 0 ? elapsed : 0,
          activeLogId: activeLogId,
        );
      }

      // 2. Check EachEmployeeAttendance for today
      final attRes = await _client.dio.post(
        ApiEndpoints.eachEmployeeAttendance,
        data: {'EmpId': empId, 'LoginId': loginId},
      );

      if (attRes.statusCode == 200 && attRes.data is List) {
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        for (var d in attRes.data) {
          if (d is Map && d['AttendaceDate']?.toString() == todayStr) {
            final list = d['lstofAttendance'] as List?;
            if (list != null && list.isNotEmpty) {
              final first = list[0] as Map;
              final inTime = first['LogInTime']?.toString() ?? '00:00:00';
              final outTime = first['LogOutTime']?.toString() ?? '00:00:00';

              if (inTime != '00:00:00' && (outTime == '00:00:00' || outTime.isEmpty)) {
                // Currently clocked in
                final parts = inTime.split(':');
                final h = int.tryParse(parts[0]) ?? now.hour;
                final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? now.minute;
                final s = int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
                final clockIn = DateTime(now.year, now.month, now.day, h, m, s);
                final elapsed = now.difference(clockIn).inSeconds;

                return LivePunchStatus(
                  isClockedIn: true,
                  clockInTimeStr: inTime.substring(0, 5),
                  workedSeconds: elapsed > 0 ? elapsed : 0,
                );
              } else if (inTime != '00:00:00' && outTime != '00:00:00') {
                // Completed shift
                final wh = first['WorkingHours']?.toString() ?? '00:00:00';
                final parts = wh.split(':');
                final totalSec = (int.tryParse(parts[0]) ?? 0) * 3600 +
                    (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0) * 60 +
                    (int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0);

                return LivePunchStatus(
                  isClockedIn: false,
                  isShiftComplete: true,
                  clockInTimeStr: inTime.substring(0, 5),
                  clockOutTimeStr: outTime.substring(0, 5),
                  workedSeconds: totalSec,
                );
              }
            }
          }
        }
      }

      return LivePunchStatus(isClockedIn: false, workedSeconds: 0);
    } catch (_) {
      return LivePunchStatus(isClockedIn: false, workedSeconds: 0);
    }
  }

  /// Clock in / on-site punch
  Future<bool> punchIn({
    required int loginId,
    required String empCode,
    double lat = 12.9716,
    double lng = 77.5946,
    String address = 'HQ Bengaluru',
  }) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.onSiteLogin,
        data: {
          'LoginId': loginId,
          'EmpCode': empCode,
          'LoginAddress': address,
          'LoginCity': 'Bengaluru',
          'LoginLatitude': lat.toString(),
          'LoginLongitude': lng.toString(),
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Clock out / on-site punch
  Future<bool> punchOut({
    required int loginId,
    int? logId,
    double lat = 12.9716,
    double lng = 77.5946,
    String address = 'HQ Bengaluru',
  }) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.onSiteLogout,
        data: {
          'LoginId': loginId,
          'Id': logId ?? 0,
          'LogoutAddress': address,
          'LogoutCity': 'Bengaluru',
          'LogoutLatitude': lat.toString(),
          'LogoutLongitude': lng.toString(),
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches real upcoming holidays and celebrations
  Future<DashboardEventData> fetchDashboardEvents(int loginId, int leId) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.employeeEvents,
        data: {'LoginId': loginId, 'LEId': leId},
      );

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final rawHolidays = data['lstofholiday'] as List? ?? [];
        final bdayMap = data['lstofbirthday'] as Map<String, dynamic>? ?? {};
        final weekCount = (bdayMap['weekcount'] as num?)?.toInt() ?? 0;

        final holidays = rawHolidays.map((h) => Map<String, dynamic>.from(h as Map)).toList();
        return DashboardEventData(holidays: holidays, weekCelebrationsCount: weekCount);
      }
      return DashboardEventData(holidays: [], weekCelebrationsCount: 0);
    } catch (_) {
      return DashboardEventData(holidays: [], weekCelebrationsCount: 0);
    }
  }

  /// Fetches real pending To-Dos & alerts
  Future<List<Map<String, dynamic>>> fetchToDos(int empId) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.myToDos,
        data: {'EmpId': empId},
      );

      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches real leave history
  Future<List<Map<String, dynamic>>> fetchMyLeaves(int empId, int loginId) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.myLeaves,
        data: {'EmpId': empId, 'LoginId': loginId},
      );

      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches real employee directory
  Future<List<Map<String, dynamic>>> fetchEmployeeDirectory(int loginId) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.employeeDirectory,
        data: {'LoginId': loginId},
      );

      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches real expense claims
  Future<List<Map<String, dynamic>>> fetchExpenses(int empId) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.myExpenseRequests,
        data: {'EmpId': empId},
      );

      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
