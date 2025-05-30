import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SadhanaProvider with ChangeNotifier {
  // Auth and Database Services
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoggedIn = false;
  String _currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  String _username = '';
  String? _userPhotoUrl;
  String? _userId;

  // Flag to prevent interference during signup
  bool _isInSignupProcess = false;

  // Jebam data
  int _jebamCount = 0;
  Map<String, int> _jebamHeatmap = {};

  // Yes/No status for other practices
  bool _tharpanamStatus = false;
  bool _homamStatus = false;
  bool _dhaanamStatus = false;

  // Monthly records
  Map<String, Map<String, dynamic>> _monthlyRecords = {};
  bool _isLoading = false;

  // FIXED: Add navigation lock to prevent conflicts
  bool _isNavigationLocked = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get currentMonth => _currentMonth;
  String get username => _username;
  String? get userPhotoUrl => _userPhotoUrl;
  String? get userId => _userId;
  int get jebamCount => _jebamCount;
  Map<String, int> get jebamHeatmap => _jebamHeatmap;
  bool get tharpanamStatus => _tharpanamStatus;
  bool get homamStatus => _homamStatus;
  bool get dhaanamStatus => _dhaanamStatus;
  Map<String, Map<String, dynamic>> get monthlyRecords => _monthlyRecords;
  bool get isLoading => _isLoading;
  bool get isInSignupProcess => _isInSignupProcess;

  // Constructor - Load data on initialization
  SadhanaProvider() {
    _init();
  }

  // Initialize provider
  Future<void> _init() async {
    await _loadInitialData();
    _setupAuthListener();
  }

  // Methods to control signup process
  void setSignupProcessActive(bool active) {
    debugPrint('Setting signup process active: $active');
    _isInSignupProcess = active;
    notifyListeners();
  }

  // FIXED: Improved auth state listener with better conflict handling
  void _setupAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      debugPrint('Auth state changed: ${user?.uid}, signup in progress: $_isInSignupProcess, navigation locked: $_isNavigationLocked');
      
      // Don't interfere during signup process or when navigation is locked
      if (_isInSignupProcess || _isNavigationLocked) {
        debugPrint('Auth state change ignored - signup in progress or navigation locked');
        return;
      }

      if (user != null) {
        // User is logged in
        if (!_isLoggedIn) {
          debugPrint('User logged in: ${user.uid}');
          _isLoggedIn = true;
          _userId = user.uid;
          _username = user.displayName ?? user.email?.split('@')[0] ?? 'User';
          _userPhotoUrl = user.photoURL;

          // Load user data from Firestore
          await _loadUserDataFromFirestore();
          notifyListeners();
        }
      } else {
        // User is logged out
        if (_isLoggedIn) {
          debugPrint('User logged out');
          _isLoggedIn = false;
          _userId = null;
          _username = '';
          _userPhotoUrl = null;
          notifyListeners();
        }
      }
    });
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    _setLoading(true);

    // Check if user is logged in
    User? currentUser = _authService.currentUser;

    if (currentUser != null) {
      _isLoggedIn = true;
      _userId = currentUser.uid;
      _username =
          currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
      _userPhotoUrl = currentUser.photoURL;

      // Load user data from Firestore
      await _loadUserDataFromFirestore();
    } else {
      // Load data from SharedPreferences for compatibility
      await _loadDataFromSharedPreferences();
    }

    _setLoading(false);
  }

  // Load user data from Firestore
  Future<void> _loadUserDataFromFirestore() async {
    if (_userId == null) return;

    try {
      // Get user profile data
      Map<String, dynamic>? userData = await _databaseService.getUserById(
        _userId!,
      );

      if (userData != null) {
        _username = userData['name'] ?? _username;
        _userPhotoUrl = userData['imgUrl'];
      }

      // Get jebam heatmap data
      Map<String, int>? heatmapData = await _databaseService.getJebamHeatmap(
        _userId!,
      );

      if (heatmapData != null) {
        _jebamHeatmap = heatmapData;
      }

      // Get current month's data
      Map<String, dynamic>? monthData = await _databaseService
          .getSadhanaDataForMonth(_userId!, _currentMonth);

      if (monthData != null) {
        _jebamCount = monthData['jebamCount'] ?? 0;
        _tharpanamStatus = monthData['tharpanamStatus'] ?? false;
        _homamStatus = monthData['homamStatus'] ?? false;
        _dhaanamStatus = monthData['dhaanamStatus'] ?? false;
      }

      // Get all monthly records
      List<Map<String, dynamic>> allData = await _databaseService
          .getAllSadhanaData(_userId!);

      _monthlyRecords = {};
      for (var data in allData) {
        String month = data['month'] ?? '';
        if (month.isNotEmpty) {
          _monthlyRecords[month] = data;
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading Firestore data: $e');

      // Fallback to local data
      await _loadDataFromSharedPreferences();
    }
  }

  // Load legacy data from SharedPreferences
  Future<void> _loadDataFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _username = prefs.getString('username') ?? '';

      // Load current month's data
      _jebamCount = prefs.getInt('jebamCount_$_currentMonth') ?? 0;

      // Load heatmap data
      final heatmapStr = prefs.getString('jebamHeatmap') ?? '{}';
      _jebamHeatmap = Map<String, int>.from(jsonDecode(heatmapStr));

      // Load practice statuses
      _tharpanamStatus =
          prefs.getBool('tharpanamStatus_$_currentMonth') ?? false;
      _homamStatus = prefs.getBool('homamStatus_$_currentMonth') ?? false;
      _dhaanamStatus = prefs.getBool('dhaanamStatus_$_currentMonth') ?? false;

      // Load monthly records
      final monthlyRecordsStr = prefs.getString('monthlyRecords') ?? '{}';
      try {
        _monthlyRecords = Map<String, Map<String, dynamic>>.from(
          jsonDecode(monthlyRecordsStr).map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
          ),
        );
      } catch (e) {
        // If there's an error parsing, start with empty records
        _monthlyRecords = {};
      }

      notifyListeners();
    } catch (e) {
      print('Error loading SharedPreferences data: $e');
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Save current month data to Firestore
  Future<void> _saveCurrentMonthToFirestore() async {
    if (_userId == null) return;

    try {
      Map<String, dynamic> monthData = {
        'month': _currentMonth,
        'jebamCount': _jebamCount,
        'tharpanamStatus': _tharpanamStatus,
        'homamStatus': _homamStatus,
        'dhaanamStatus': _dhaanamStatus,
      };

      await _databaseService.saveSadhanaData(_userId!, monthData);

      // Update monthly records
      if (!_monthlyRecords.containsKey(_currentMonth)) {
        _monthlyRecords[_currentMonth] = {};
      }
      _monthlyRecords[_currentMonth] = monthData;

      // Save heatmap data
      await _databaseService.saveJebamHeatmap(_userId!, _jebamHeatmap);
    } catch (e) {
      print('Error saving to Firestore: $e');
      await _saveDataToSharedPreferences();
    }
  }

  // Save data to SharedPreferences (backup/offline functionality)
  Future<void> _saveDataToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', _isLoggedIn);
      await prefs.setString('username', _username);

      // Save current month's data
      await prefs.setInt('jebamCount_$_currentMonth', _jebamCount);

      // Save heatmap data
      await prefs.setString('jebamHeatmap', jsonEncode(_jebamHeatmap));

      // Save practice statuses
      await prefs.setBool('tharpanamStatus_$_currentMonth', _tharpanamStatus);
      await prefs.setBool('homamStatus_$_currentMonth', _homamStatus);
      await prefs.setBool('dhaanamStatus_$_currentMonth', _dhaanamStatus);

      // Save monthly records
      await prefs.setString('monthlyRecords', jsonEncode(_monthlyRecords));
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
    }
  }

  // FIXED: Login with proper navigation control
  Future<void> login(String email, String password) async {
    _setLoading(true);

    try {
      // Lock navigation during login
      _isNavigationLocked = true;
      
      // Disable signup protection when doing actual login
      _isInSignupProcess = false;
      
      await _authService.signInWithEmailAndPassword(email, password);

      // Wait for auth state to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Load user data from Firestore
      await _loadUserDataFromFirestore();

      // Save the login state to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Update state
      _isLoggedIn = true;
      
    } catch (e) {
      // Login failed
      _isLoggedIn = false;
      rethrow; // Rethrow to handle in UI
    } finally {
      _isNavigationLocked = false;
      _setLoading(false);
    }
  }

  // Register with Firebase
  Future<void> register(String name, String email, String password) async {
    _setLoading(true);

    try {
      UserCredential userCredential = await _authService
          .registerWithEmailAndPassword(name, email, password);

      _userId = userCredential.user!.uid;
      _username = name;
      _isLoggedIn = true;

      // Save initial data to SharedPreferences and Firestore
      await _saveDataToSharedPreferences();
      await _saveCurrentMonthToFirestore();
    } catch (e) {
      _isLoggedIn = false;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: Google Sign-In with proper navigation control
  Future<void> signInWithGoogle() async {
    _setLoading(true);

    try {
      // Lock navigation during Google sign-in
      _isNavigationLocked = true;
      
      // Disable signup protection for Google sign-in
      _isInSignupProcess = false;
      
      User? user = await _authService.signInWithGoogle();

      if (user != null) {
        _userId = user.uid;
        _username = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        _userPhotoUrl = user.photoURL;
        _isLoggedIn = true;

        // Wait for auth state to update
        await Future.delayed(const Duration(milliseconds: 500));

        // Load user data
        await _loadUserDataFromFirestore();
      } else {
        // Sign in canceled by user
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
      rethrow;
    } finally {
      _isNavigationLocked = false;
      _setLoading(false);
    }
  }

  // Logout function
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.signOut();

      _isLoggedIn = false;
      _userId = null;
      _username = '';
      _userPhotoUrl = null;

      // Clear SharedPreferences login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update Jebam count
  Future<void> updateJebamCount(int count) async {
    _jebamCount = count;

    // Update today's entry in heatmap
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _jebamHeatmap[today] = count;

    // Update monthly records
    if (!_monthlyRecords.containsKey(_currentMonth)) {
      _monthlyRecords[_currentMonth] = {};
    }
    _monthlyRecords[_currentMonth]!['jebamCount'] = _jebamCount;

    // Save data
    await _saveCurrentMonthToFirestore();
    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Update specific date in Jebam heatmap
  Future<void> updateJebamHeatmap(String dateStr, int count) async {
    _jebamHeatmap[dateStr] = count;

    if (_userId != null) {
      await _databaseService.saveJebamHeatmap(_userId!, _jebamHeatmap);
    }
    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Get month's total from heatmap
  int getMonthJebamTotal(int year, int month) {
    int total = 0;

    // Get all dates in the specified month
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      if (_jebamHeatmap.containsKey(dateStr)) {
        total += _jebamHeatmap[dateStr] ?? 0;
      }
    }

    return total;
  }

  // Get data for a specific month
  Map<String, dynamic>? getMonthData(String monthKey) {
    return _monthlyRecords[monthKey];
  }

  // Update Tharpanam status
  Future<void> updateTharpanamStatus(bool status) async {
    _tharpanamStatus = status;

    // Update monthly records
    if (!_monthlyRecords.containsKey(_currentMonth)) {
      _monthlyRecords[_currentMonth] = {};
    }
    _monthlyRecords[_currentMonth]!['tharpanamStatus'] = _tharpanamStatus;

    await _saveCurrentMonthToFirestore();
    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Update Tharpanam status for a specific month
  Future<void> updateTharpanamStatusForMonth(
    int year,
    int month,
    bool status,
  ) async {
    final monthKey = DateFormat('MMMM yyyy').format(DateTime(year, month));

    if (!_monthlyRecords.containsKey(monthKey)) {
      _monthlyRecords[monthKey] = {};
    }

    _monthlyRecords[monthKey]!['tharpanamStatus'] = status;

    // If this is the current month, also update the current status
    if (monthKey == _currentMonth) {
      _tharpanamStatus = status;
    }

    // Create month data for Firestore
    Map<String, dynamic> monthData = {
      'month': monthKey,
      'tharpanamStatus': status,
      'homamStatus': _monthlyRecords[monthKey]!['homamStatus'] ?? false,
      'dhaanamStatus': _monthlyRecords[monthKey]!['dhaanamStatus'] ?? false,
      'jebamCount': _monthlyRecords[monthKey]!['jebamCount'] ?? 0,
    };

    // Save to Firestore if logged in
    if (_userId != null) {
      await _databaseService.saveSadhanaData(_userId!, monthData);
    }

    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Update Homam status
  Future<void> updateHomamStatus(bool status) async {
    _homamStatus = status;

    // Update monthly records
    if (!_monthlyRecords.containsKey(_currentMonth)) {
      _monthlyRecords[_currentMonth] = {};
    }
    _monthlyRecords[_currentMonth]!['homamStatus'] = _homamStatus;

    await _saveCurrentMonthToFirestore();
    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Update Homam status for a specific month
  Future<void> updateHomamStatusForMonth(
    int year,
    int month,
    bool status,
  ) async {
    final monthKey = DateFormat('MMMM yyyy').format(DateTime(year, month));

    if (!_monthlyRecords.containsKey(monthKey)) {
      _monthlyRecords[monthKey] = {};
    }

    _monthlyRecords[monthKey]!['homamStatus'] = status;

    // If this is the current month, also update the current status
    if (monthKey == _currentMonth) {
      _homamStatus = status;
    }

    // Create month data for Firestore
    Map<String, dynamic> monthData = {
      'month': monthKey,
      'homamStatus': status,
      'tharpanamStatus': _monthlyRecords[monthKey]!['tharpanamStatus'] ?? false,
      'dhaanamStatus': _monthlyRecords[monthKey]!['dhaanamStatus'] ?? false,
      'jebamCount': _monthlyRecords[monthKey]!['jebamCount'] ?? 0,
    };

    // Save to Firestore if logged in
    if (_userId != null) {
      await _databaseService.saveSadhanaData(_userId!, monthData);
    }

    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Update Dhaanam status
  Future<void> updateDhaanamStatus(bool status) async {
    _dhaanamStatus = status;

    // Update monthly records
    if (!_monthlyRecords.containsKey(_currentMonth)) {
      _monthlyRecords[_currentMonth] = {};
    }
    _monthlyRecords[_currentMonth]!['dhaanamStatus'] = _dhaanamStatus;

    await _saveCurrentMonthToFirestore();
    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Update Dhaanam status for a specific month
  Future<void> updateDhaanamStatusForMonth(
    int year,
    int month,
    bool status,
  ) async {
    final monthKey = DateFormat('MMMM yyyy').format(DateTime(year, month));

    if (!_monthlyRecords.containsKey(monthKey)) {
      _monthlyRecords[monthKey] = {};
    }

    _monthlyRecords[monthKey]!['dhaanamStatus'] = status;

    // If this is the current month, also update the current status
    if (monthKey == _currentMonth) {
      _dhaanamStatus = status;
    }

    // Create month data for Firestore
    Map<String, dynamic> monthData = {
      'month': monthKey,
      'dhaanamStatus': status,
      'tharpanamStatus': _monthlyRecords[monthKey]!['tharpanamStatus'] ?? false,
      'homamStatus': _monthlyRecords[monthKey]!['homamStatus'] ?? false,
      'jebamCount': _monthlyRecords[monthKey]!['jebamCount'] ?? 0,
    };

    // Save to Firestore if logged in
    if (_userId != null) {
      await _databaseService.saveSadhanaData(_userId!, monthData);
    }

    await _saveDataToSharedPreferences();

    notifyListeners();
  }

  // Set current active month
  void setActiveMonth(int year, int month) async {
    final newMonthKey = DateFormat('MMMM yyyy').format(DateTime(year, month));
    _currentMonth = newMonthKey;

    // Load statuses for the new month
    if (_monthlyRecords.containsKey(newMonthKey)) {
      _tharpanamStatus =
          _monthlyRecords[newMonthKey]!['tharpanamStatus'] as bool? ?? false;
      _homamStatus =
          _monthlyRecords[newMonthKey]!['homamStatus'] as bool? ?? false;
      _dhaanamStatus =
          _monthlyRecords[newMonthKey]!['dhaanamStatus'] as bool? ?? false;
      _jebamCount = _monthlyRecords[newMonthKey]!['jebamCount'] as int? ?? 0;
    } else {
      // Initialize empty records for new month
      _tharpanamStatus = false;
      _homamStatus = false;
      _dhaanamStatus = false;
      _jebamCount = 0;
    }

    notifyListeners();
  }

  // Get total Jebam count from all months
  int getTotalJebamCount() {
    int total = 0;
    _monthlyRecords.forEach((month, data) {
      total += data['jebamCount'] as int? ?? 0;
    });
    return total;
  }

  // Get completion statistics
  Map<String, int> getCompletionStats() {
    int totalTharpanam = 0;
    int totalHomam = 0;
    int totalDhaanam = 0;

    _monthlyRecords.forEach((month, data) {
      if (data['tharpanamStatus'] as bool? ?? false) totalTharpanam++;
      if (data['homamStatus'] as bool? ?? false) totalHomam++;
      if (data['dhaanamStatus'] as bool? ?? false) totalDhaanam++;
    });

    return {
      'tharpanam': totalTharpanam,
      'homam': totalHomam,
      'dhaanam': totalDhaanam,
    };
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);

    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String name, {String? photoUrl}) async {
    _setLoading(true);

    try {
      Map<String, dynamic> updateData = {'name': name};

      if (photoUrl != null) {
        updateData['imgUrl'] = photoUrl;
      }

      if (_userId != null) {
        await _databaseService.updateUser(_userId!, updateData);
      }

      _username = name;
      if (photoUrl != null) {
        _userPhotoUrl = photoUrl;
      }

      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}