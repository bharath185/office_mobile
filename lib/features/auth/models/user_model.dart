class UserModel {
  final int empId;
  final int loginId;
  final String empCode;
  final String fullName;
  final String email;
  final String mobileNo;
  final String designation;
  final String department;
  final String company;
  final String? reportEmpCode;
  final String? profilePhotoUrl;
  final int? roleId;
  final int? leId;
  final bool isReportingManager;
  final String? tokenId;

  UserModel({
    required this.empId,
    required this.loginId,
    required this.empCode,
    required this.fullName,
    required this.email,
    this.mobileNo = '',
    required this.designation,
    required this.department,
    this.company = '3DCAD',
    this.reportEmpCode,
    this.profilePhotoUrl,
    this.roleId,
    this.leId = 1,
    this.isReportingManager = false,
    this.tokenId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final first = (json['FirstName'] ?? json['firstName'] ?? '').toString().trim();
    final middle = (json['MiddleName'] ?? json['middleName'] ?? '').toString().trim();
    final last = (json['LastName'] ?? json['lastName'] ?? '').toString().trim();
    final combined = [first, middle, last].where((s) => s.isNotEmpty).join(' ');

    final rawName = (json['FullName'] ?? json['EmpName'] ?? json['fullName'] ?? json['empName'] ?? '').toString().trim();
    final finalName = combined.isNotEmpty ? combined : (rawName.isNotEmpty ? rawName : 'Employee');

    final empIdVal = json['EmpId'] ?? json['empId'] ?? json['LoginId'] ?? json['loginId'] ?? 0;
    final loginIdVal = json['LoginId'] ?? json['loginId'] ?? empIdVal;

    return UserModel(
      empId: empIdVal is int ? empIdVal : int.tryParse(empIdVal.toString()) ?? 0,
      loginId: loginIdVal is int ? loginIdVal : int.tryParse(loginIdVal.toString()) ?? 0,
      empCode: (json['EmpCode'] ?? json['empCode'] ?? json['UserName'] ?? json['userName'] ?? '').toString().trim(),
      fullName: finalName,
      email: (json['EmailId'] ?? json['emailId'] ?? json['email'] ?? '').toString().trim(),
      mobileNo: (json['MobileNo'] ?? json['mobileNo'] ?? '').toString().trim(),
      designation: (json['Designation'] ?? json['DesignationName'] ?? json['designation'] ?? 'Staff').toString().trim(),
      department: (json['DeptName'] ?? json['Department'] ?? json['department'] ?? 'General').toString().trim(),
      company: (json['Company'] ?? json['company'] ?? '3DCAD').toString().trim(),
      reportEmpCode: json['ReportEmpCode']?.toString(),
      profilePhotoUrl: json['ProfilePhotoUrl'] ?? json['Photo'] ?? json['profilePhotoUrl'],
      roleId: json['RoleId'] ?? json['roleId'],
      leId: json['LEId'] ?? json['leId'] ?? 1,
      isReportingManager: json['IsReportingManager'] ?? (json['ReportId'] != null),
      tokenId: json['TokenId'] ?? json['tokenId'] ?? json['UserAuth'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EmpId': empId,
      'LoginId': loginId,
      'EmpCode': empCode,
      'FullName': fullName,
      'EmailId': email,
      'MobileNo': mobileNo,
      'Designation': designation,
      'DeptName': department,
      'Company': company,
      'ReportEmpCode': reportEmpCode,
      'ProfilePhotoUrl': profilePhotoUrl,
      'RoleId': roleId,
      'LEId': leId,
      'IsReportingManager': isReportingManager,
      'TokenId': tokenId,
    };
  }
}
