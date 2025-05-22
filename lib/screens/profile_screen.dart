import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/sadhana_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUpdatingProfile = false;
  bool _isGoogleUser = false;

  // Login Screen Theme Colors (matching login_screen.dart)
  final Color _primaryDark = const Color(0xFF0D2B3E);    // Deep teal/midnight blue
  final Color _primaryMedium = const Color(0xFF1A4A6E);  // Medium teal blue
  final Color _accentColor = const Color(0xFFD8B468);    // Gentle gold/amber
  final Color _errorColor = const Color(0xFFCF6679);     // Soft rose for errors
  final Color _textColor = Colors.white;
  final Color _inputBgColor = const Color(0x26FFFFFF);   // White with 15% opacity
  final Color _focusedBorderColor = const Color(0xFFD8B468); // Gold for focus
  final Color _unfocusedBorderColor = const Color(0x33FFFFFF); // White with 20% opacity

  @override
  void initState() {
    super.initState();
    _checkUserAuthProvider();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _checkUserAuthProvider() {
    final user = AuthService().currentUser;
    if (user != null) {
      // Check if user signed in with Google
      for (UserInfo userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          _isGoogleUser = true;
          break;
        }
      }
    }

    // Initialize TabController based on user type
    _tabController = TabController(
      length: _isGoogleUser ? 1 : 2, 
      vsync: this
    );
  }

  void _loadUserData() {
    final sadhanaProvider = Provider.of<SadhanaProvider>(
      context,
      listen: false,
    );
    _nameController.text = sadhanaProvider.username;
    _emailController.text = AuthService().currentUser?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final sadhanaProvider = Provider.of<SadhanaProvider>(context);
    final username = sadhanaProvider.username;
    final userPhotoUrl = sadhanaProvider.userPhotoUrl;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryDark,
              _primaryMedium,
              const Color(0xFF2A5E80), // Slightly lighter blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/subtle_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Profile header with photo
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile photo with edit option
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: _primaryDark,
                            backgroundImage: _getProfileImage(userPhotoUrl),
                            child: _getProfileImage(userPhotoUrl) == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: _accentColor,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _showImagePickerOptions,
                            ),
                          ),
                        ),
                        if (_isUpdatingProfile)
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _accentColor,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Username
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                        shadows: const [
                          Shadow(
                            color: Color(0x40000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      AuthService().currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: _textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar (only show if not Google user or show single tab)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _accentColor,
                  indicatorWeight: 3,
                  labelColor: _accentColor,
                  unselectedLabelColor: _textColor.withOpacity(0.7),
                  tabs: _isGoogleUser 
                    ? [
                        const Tab(icon: Icon(Icons.person), text: 'Profile'),
                      ]
                    : [
                        const Tab(icon: Icon(Icons.person), text: 'Profile'),
                        const Tab(icon: Icon(Icons.lock), text: 'Password'),
                      ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _isGoogleUser 
                    ? [
                        _buildProfileTab(),
                      ]
                    : [
                        _buildProfileTab(),
                        _buildPasswordTab(),
                      ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Info Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name field
                    _buildTextFormField(
                      controller: _nameController,
                      labelText: 'Name',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email field (read-only)
                    _buildTextFormField(
                      controller: _emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                      readOnly: true,
                      enabled: false,
                    ),

                    const SizedBox(height: 30),

                    // Update button
                    SizedBox(
                      width: double.infinity,
                      child: _buildPrimaryButton(
                        isLoading: _isUpdatingProfile,
                        onPressed: _isUpdatingProfile ? null : _updateProfile,
                        label: 'Update Profile',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sign out button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign out button
                  Container(
                    decoration: BoxDecoration(
                      color: _errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.logout, color: _errorColor),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: _errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: _confirmSignOut,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),

                const SizedBox(height: 20),

                // Current password
                _buildTextFormField(
                  controller: _currentPasswordController,
                  labelText: 'Current Password',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // New password
                _buildTextFormField(
                  controller: _newPasswordController,
                  labelText: 'New Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm new password
                _buildTextFormField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm New Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Update button
                SizedBox(
                  width: double.infinity,
                  child: _buildPrimaryButton(
                    isLoading: _isUpdatingProfile,
                    onPressed: _isUpdatingProfile ? null : _changePassword,
                    label: 'Change Password',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool readOnly = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      style: TextStyle(
        fontSize: 16,
        color: enabled ? _textColor : _textColor.withOpacity(0.5),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: enabled ? 'Enter your $labelText' : null,
        prefixIcon: Icon(
          prefixIcon,
          color: enabled ? _accentColor : _textColor.withOpacity(0.5),
        ),
        labelStyle: TextStyle(
          color: enabled ? _textColor : _textColor.withOpacity(0.5),
        ),
        hintStyle: TextStyle(
          color: _textColor.withOpacity(0.5),
        ),
        filled: true,
        fillColor: enabled ? _inputBgColor : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _focusedBorderColor,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _unfocusedBorderColor,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _errorColor,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _errorColor,
            width: 1.5,
          ),
        ),
        errorStyle: TextStyle(
          color: _errorColor,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required bool isLoading,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFDAB35C), // Slightly brighter gold
            _accentColor,
            const Color(0xFFBE975B), // Darker gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage(String? photoUrl) {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      } else if (photoUrl.startsWith('data:image')) {
        // Handle base64 image
        String base64String = photoUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
    }
    return null;
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (builder) {
        return Container(
          decoration: BoxDecoration(
            color: _primaryMedium,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera option
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _accentColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 32,
                                color: _accentColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera',
                              style: TextStyle(color: _textColor),
                            ),
                          ],
                        ),
                      ),

                      // Gallery option
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _accentColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.photo_library,
                                size: 32,
                                color: _accentColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: TextStyle(color: _textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Remove photo option
                  if (Provider.of<SadhanaProvider>(
                        context,
                        listen: false,
                      ).userPhotoUrl !=
                      null)
                    OutlinedButton.icon(
                      icon: Icon(Icons.delete, color: _errorColor),
                      label: Text(
                        'Remove Photo',
                        style: TextStyle(color: _errorColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _errorColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _removeProfilePhoto();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUpdatingProfile = true;
        });

        // Upload image and update profile
        await _uploadProfileImage();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      if (_imageFile == null) return;

      // Convert image to base64 for storage in Firebase
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Store as a data URL
      final imageUrl = 'data:image/jpeg;base64,$base64Image';

      // Update user profile with the image URL
      await Provider.of<SadhanaProvider>(
        context,
        listen: false,
      ).updateUserProfile(_nameController.text, photoUrl: imageUrl);

      setState(() {
        _isUpdatingProfile = false;
      });

      _showSuccessSnackBar('Profile picture updated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to update profile picture: ${e.toString()}');
      setState(() {
        _isUpdatingProfile = false;
        _imageFile = null;
      });
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      setState(() {
        _isUpdatingProfile = true;
        _imageFile = null;
      });

      // Update profile with null photo URL
      await Provider.of<SadhanaProvider>(
        context,
        listen: false,
      ).updateUserProfile(_nameController.text, photoUrl: '');

      setState(() {
        _isUpdatingProfile = false;
      });

      _showSuccessSnackBar('Profile picture removed');
    } catch (e) {
      _showErrorSnackBar('Failed to remove profile picture: ${e.toString()}');
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      // Update user profile with the name
      await Provider.of<SadhanaProvider>(
        context,
        listen: false,
      ).updateUserProfile(_nameController.text);

      _showSuccessSnackBar('Profile updated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      // Get current user
      final user = AuthService().currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create credential with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(_newPasswordController.text);

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSuccessSnackBar('Password changed successfully');
    } catch (e) {
      String errorMessage = 'Failed to change password';

      // Handle specific authentication errors
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Please sign in again and retry';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(color: _textColor),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: _textColor.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _textColor.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      setState(() {
        _isUpdatingProfile = true;
      });

      await Provider.of<SadhanaProvider>(context, listen: false).logout();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to sign out: ${e.toString()}');
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}