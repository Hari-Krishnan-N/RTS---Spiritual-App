# Environment Configuration for Notification System

## Development Environment (.env.development)
ENVIRONMENT=development
FIREBASE_PROJECT_ID=rhythmbhara-tara-sadhana-dev
NOTIFICATION_CLEANUP_INTERVAL_HOURS=1
MAX_NOTIFICATIONS_PER_USER=20
ENABLE_DEBUG_LOGGING=true
ENABLE_PERFORMANCE_MONITORING=true
NOTIFICATION_POLLING_INTERVAL_SECONDS=10

## Staging Environment (.env.staging)
ENVIRONMENT=staging
FIREBASE_PROJECT_ID=rhythmbhara-tara-sadhana-staging
NOTIFICATION_CLEANUP_INTERVAL_HOURS=6
MAX_NOTIFICATIONS_PER_USER=15
ENABLE_DEBUG_LOGGING=true
ENABLE_PERFORMANCE_MONITORING=true
NOTIFICATION_POLLING_INTERVAL_SECONDS=30

## Production Environment (.env.production)
ENVIRONMENT=production
FIREBASE_PROJECT_ID=rhythmbhara-tara-sadhana-517d0
NOTIFICATION_CLEANUP_INTERVAL_HOURS=24
MAX_NOTIFICATIONS_PER_USER=10
ENABLE_DEBUG_LOGGING=false
ENABLE_PERFORMANCE_MONITORING=true
NOTIFICATION_POLLING_INTERVAL_SECONDS=30

## Configuration Class Implementation

```dart
// lib/config/notification_environment_config.dart
import 'package:flutter/foundation.dart';

class NotificationEnvironmentConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'rhythmbhara-tara-sadhana-517d0',
  );
  
  static const int cleanupIntervalHours = int.fromEnvironment(
    'NOTIFICATION_CLEANUP_INTERVAL_HOURS',
    defaultValue: 24,
  );
  
  static const int maxNotificationsPerUser = int.fromEnvironment(
    'MAX_NOTIFICATIONS_PER_USER',
    defaultValue: 10,
  );
  
  static const bool enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: kDebugMode,
  );
  
  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );
  
  static const int pollingIntervalSeconds = int.fromEnvironment(
    'NOTIFICATION_POLLING_INTERVAL_SECONDS',
    defaultValue: 30,
  );

  // Derived configurations
  static Duration get cleanupInterval => Duration(hours: cleanupIntervalHours);
  static Duration get pollingInterval => Duration(seconds: pollingIntervalSeconds);
  
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
  
  // Notification channels based on environment
  static String get defaultNotificationChannel {
    switch (environment) {
      case 'development':
        return 'dev_notifications';
      case 'staging':
        return 'staging_notifications';
      default:
        return 'prod_notifications';
    }
  }
  
  // Database collection prefixes
  static String get collectionPrefix {
    switch (environment) {
      case 'development':
        return 'dev_';
      case 'staging':
        return 'staging_';
      default:
        return '';
    }
  }
  
  // Logging configuration
  static void logConfig(String message) {
    if (enableDebugLogging) {
      debugPrint('[NotificationConfig] $message');
    }
  }
  
  // Performance monitoring
  static void trackPerformance(String operation, Duration duration) {
    if (enablePerformanceMonitoring) {
      logConfig('Performance: $operation took ${duration.inMilliseconds}ms');
      
      // In production, you might want to send this to analytics
      if (isProduction && duration.inMilliseconds > 1000) {
        // Send to crash analytics or performance monitoring service
        debugPrint('Slow operation detected: $operation (${duration.inMilliseconds}ms)');
      }
    }
  }
  
  // Configuration validation
  static bool validateConfiguration() {
    final validations = [
      firebaseProjectId.isNotEmpty,
      maxNotificationsPerUser > 0,
      maxNotificationsPerUser <= 50, // Reasonable upper limit
      cleanupIntervalHours > 0,
      pollingIntervalSeconds >= 10, // Minimum polling interval
    ];
    
    return validations.every((validation) => validation);
  }
  
  // Print current configuration
  static void printConfiguration() {
    if (enableDebugLogging) {
      debugPrint('''
🔧 Notification System Configuration:
   Environment: $environment
   Firebase Project: $firebaseProjectId
   Max Notifications/User: $maxNotificationsPerUser
   Cleanup Interval: ${cleanupInterval.inHours}h
   Polling Interval: ${pollingInterval.inSeconds}s
   Debug Logging: $enableDebugLogging
   Performance Monitoring: $enablePerformanceMonitoring
   Valid Configuration: ${validateConfiguration()}
      ''');
    }
  }
}
```

## Usage in Code

```dart
// Initialize with environment configuration
class ImprovedNotificationService {
  Future<void> initialize() async {
    NotificationEnvironmentConfig.printConfiguration();
    
    if (!NotificationEnvironmentConfig.validateConfiguration()) {
      throw Exception('Invalid notification configuration');
    }
    
    // Use environment-specific settings
    _maxNotificationsPerUser = NotificationEnvironmentConfig.maxNotificationsPerUser;
    _cleanupInterval = NotificationEnvironmentConfig.cleanupInterval;
    _pollingInterval = NotificationEnvironmentConfig.pollingInterval;
    
    // Setup with environment-specific channel
    await _setupNotificationChannels(NotificationEnvironmentConfig.defaultNotificationChannel);
  }
}
```

## Build Configuration

### Android (android/app/build.gradle)
```gradle
android {
    buildTypes {
        debug {
            buildConfigField "String", "ENVIRONMENT", '"development"'
            buildConfigField "String", "FIREBASE_PROJECT_ID", '"rhythmbhara-tara-sadhana-dev"'
        }
        
        staging {
            buildConfigField "String", "ENVIRONMENT", '"staging"'
            buildConfigField "String", "FIREBASE_PROJECT_ID", '"rhythmbhara-tara-sadhana-staging"'
        }
        
        release {
            buildConfigField "String", "ENVIRONMENT", '"production"'
            buildConfigField "String", "FIREBASE_PROJECT_ID", '"rhythmbhara-tara-sadhana-517d0"'
        }
    }
}
```

### Flutter Build Commands
```bash
# Development build
flutter build apk --dart-define=ENVIRONMENT=development --dart-define=ENABLE_DEBUG_LOGGING=true

# Staging build
flutter build apk --dart-define=ENVIRONMENT=staging --dart-define=MAX_NOTIFICATIONS_PER_USER=15

# Production build
flutter build apk --dart-define=ENVIRONMENT=production --dart-define=ENABLE_DEBUG_LOGGING=false
```

## Environment-Specific Firebase Projects

### Development
- Project ID: `rhythmbhara-tara-sadhana-dev`
- Use case: Local development and testing
- Data retention: 7 days
- Debug logging: Enabled

### Staging
- Project ID: `rhythmbhara-tara-sadhana-staging`
- Use case: Pre-production testing
- Data retention: 30 days
- Debug logging: Enabled

### Production
- Project ID: `rhythmbhara-tara-sadhana-517d0`
- Use case: Live app
- Data retention: As per policy
- Debug logging: Disabled

## Monitoring and Alerts

### Development
- All logs enabled
- No performance alerts
- Immediate error notifications

### Staging
- Performance monitoring enabled
- Alert on errors > 5% rate
- Daily performance reports

### Production
- Critical monitoring only
- Alert on errors > 1% rate
- Real-time performance monitoring
- Automatic scaling triggers
