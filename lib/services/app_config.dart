class AppConfig {
  static const String socketServerUrl = String.fromEnvironment(
    'SOCKET_SERVER_URL',
    defaultValue: 'http://172.23.200.150:3000',
  );
}
