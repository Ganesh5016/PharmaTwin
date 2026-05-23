class AppConstants {
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000/api/v1'; // iOS simulator
  static const String baseUrl = 'https://pharmatwin-tpee.onrender.com/api/v1'; // Production

  static const String appName = 'PharmaTwin AI';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String kAccessToken = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId = 'user_id';
  static const String kUserEmail = 'user_email';
  static const String kUserRole = 'user_role';

  // Timeouts
  static const int connectionTimeoutMs = 30000;
  static const int receiveTimeoutMs = 60000;

  // Pagination
  static const int defaultPageSize = 20;

  // Chart config
  static const int maxChartDataPoints = 50;

  // Risk thresholds
  static const double lowRiskThreshold = 0.3;
  static const double mediumRiskThreshold = 0.6;
  static const double highRiskThreshold = 0.8;

  // Stability score thresholds
  static const double excellentStability = 0.85;
  static const double goodStability = 0.65;
  static const double acceptableStability = 0.45;

  // Environmental limits
  static const double maxTemperatureC = 60.0;
  static const double minTemperatureC = -20.0;
  static const double maxHumidityPercent = 100.0;
  static const double minHumidityPercent = 0.0;

  // API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authMe = '/auth/me';

  static const String batchesEndpoint = '/batches';
  static const String predictionsEndpoint = '/predictions';
  static const String simulationsEndpoint = '/simulations';
  static const String reportsEndpoint = '/reports';
  static const String analyticsEndpoint = '/analytics';
  static const String adminEndpoint = '/admin';
  static const String calibrateEndpoint = '/ai/calibrate';
  static const String retrainEndpoint = '/ai/retrain';
  static const String dashboardEndpoint = '/dashboard/summary';
}
