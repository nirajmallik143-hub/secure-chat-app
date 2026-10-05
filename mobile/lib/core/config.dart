/// Override at build time: flutter build apk --dart-define=API_URL=https://api.example.com
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:4000');
