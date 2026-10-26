/// Production & Environment Backend API Endpoints Mapping to OfficeConnect Spring Boot Backend
class ApiEndpoints {
  // Production Base URL (Directly pointing to OfficeConnect Production Backend)
  static const String productionBaseUrl = 'https://newofficeconnect.3dcad-global.com:8099';
  static const String defaultBaseUrl = productionBaseUrl;

  // Local / UAT Failover URLs (Configurable via Settings screen in app)
  static const String localLanBaseUrl = 'http://192.168.2.45:8099';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8099';

  // Auth & Session
  static const String login = '/Login/Login';
  static const String logout = '/Login/LogOut';
  static const String checkAuth = '/Login/CheckAuth';
  static const String changePassword = '/Login/ChangePassword';
  static const String forgetPassword = '/Login/ForgetPassword';
  static const String userProfile = '/Employee/GetEmployee';

  // Attendance & Time Tracking (Live Production Endpoints)
  static const String eachEmployeeAttendance = '/Employee/EachEmployeeAttendance';
  static const String employeeAttendanceSummary = '/Employee/EmployeeAttendance';
  static const String allLoginLogs = '/Employee/GetAllLoginLogs';
  static const String onSiteLogin = '/Employee/OnSiteLogin';
  static const String onSiteLogout = '/Employee/OnSiteLogout';
  static const String addOnSiteData = '/Employee/AddOnSiteData';

  // Leaves & Time-Off (Live Production Endpoints)
  static const String leaveBalances = '/Leave/IndividualLeaveCount';
  static const String myLeaves = '/Leave/GetAllLeave';
  static const String leaveTypes = '/Leave/DDLeaveType';
  static const String applyLeave = '/Leave/ApplyLeave';
  static const String cancelLeave = '/Leave/CancelLeave';
  static const String withdrawLeave = '/Leave/WithDrawLeave';

  // Dashboard Events, Holidays & Celebrations (Live Production Endpoints)
  static const String employeeEvents = '/Dashboard/GetEmployeeEvents';
  static const String dashboardSummary = '/Dashboard/GetDashboardSummary';

  // To-Dos & Alerts (Live Production Endpoints)
  static const String myToDos = '/ToDo/GetMyToDos';
  static const String pendingToDos = '/ToDo/GetMyPendingToDos';
  static const String dismissToDo = '/ToDo/DismissToDo';

  // Expense Claims & Advances (Live Production Endpoints)
  static const String myExpenseRequests = '/Expense/GetAllMyRequests';
  static const String expenseCategories = '/Expense/GetAllCategory';
  static const String createExpenseRequest = '/Expense/SubmitRequest';
  static const String uploadBill = '/Expense/UploadBill';

  // Payroll & Payslips (Live Production Endpoints)
  static const String payslipByEmployee = '/Payroll/GetPayslipByEmployee';
  static const String payslipList = '/Payroll/GetAllPayslipSection';

  // Directory
  static const String employeeDirectory = '/Employee/GetAllEmployee';
}
