import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:typed_data';

import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isUploading = false;
  XFile? _selectedImage;

  Future<void> _refreshProfile() async {
    await context.read<UserProvider>().loadFromStorage();
    await context.read<GroupProvider>().loadStoredGroup();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ensurePhotoLoaded();
  }

  Future<void> _ensurePhotoLoaded() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null) {
      return;
    }

    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return;
    }

    final email = user.email.trim();
    if (email.isEmpty) {
      return;
    }

    try {
      final authUser = await FirebaseService.getAuthUserByEmail(email);
      final authPhotoUrl = authUser?['photoUrl'] as String?;
      if (!mounted || authPhotoUrl == null || authPhotoUrl.isEmpty) {
        return;
      }

      await StorageService.save('photoUrl', authPhotoUrl);
      userProvider.updateCurrentUser(photoUrl: authPhotoUrl);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() => _selectedImage = pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  /// Compress image to reduce file size
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    // Decode image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Resize to 200x200 max
    img.Image resized = img.copyResize(
      image,
      width: 200,
      height: 200,
      interpolation: img.Interpolation.average,
    );

    // Encode with high quality to maintain clarity
    final compressed = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(compressed);
  }

  Future<void> _uploadPhotoAndUpdateProfile() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final user = context.read<UserProvider>().currentUser;
      final group = context.read<GroupProvider>().currentGroup;

      if (user == null || group == null) {
        throw Exception('User or Group not found');
      }

      // Read and compress image
      var bytes = await _selectedImage!.readAsBytes();
      bytes = await _compressImage(bytes);
      final base64String = base64Encode(bytes);

      // Update Firestore with compressed Base64
      await FirebaseService.updateUserProfile(
        groupId: group.groupId,
        userId: user.userId,
        updates: {'photoUrl': base64String},
      );

      // Update local storage
      await StorageService.save('photoUrl', base64String);

      // Update provider
      final userProvider = context.read<UserProvider>();
      userProvider.updateCurrentUser(photoUrl: base64String);

      setState(() => _selectedImage = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser != null && _nameController.text == currentUser.name) {
      setState(() => _isEditing = false);
      return;
    }

    try {
      final user = context.read<UserProvider>().currentUser;
      final group = context.read<GroupProvider>().currentGroup;

      if (user == null || group == null) {
        throw Exception('User or Group not found');
      }

      await FirebaseService.updateUserProfile(
        groupId: group.groupId,
        userId: user.userId,
        updates: {'name': _nameController.text},
      );

      // Update local storage
      await StorageService.save('userName', _nameController.text);

      // Update provider
      final userProvider = context.read<UserProvider>();
      userProvider.updateCurrentUser(name: _nameController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating name: $e')));
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<AuthProvider>().logout();
                await context.read<UserProvider>().logout();
                await context.read<GroupProvider>().clearGroup();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(routeLoginSignup, (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    // Check if it's a Base64 string (doesn't start with http)
    if (!photoUrl.startsWith('http')) {
      try {
        final imageBytes = base64Decode(photoUrl);
        return MemoryImage(imageBytes);
      } catch (e) {
        return null;
      }
    }

    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed(routeSettings),
            icon: const Icon(Icons.settings_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.currentUser;
          final currentGroup = context.watch<GroupProvider>().currentGroup;
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 2,
                              ),
                            ),
                            child: _selectedImage != null
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return CircleAvatar(
                                          radius: 46,
                                          backgroundImage: MemoryImage(
                                            snapshot.data!,
                                          ),
                                        );
                                      }
                                      return const CircleAvatar(
                                        radius: 46,
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  )
                                : CircleAvatar(
                                    radius: 46,
                                    backgroundImage: _getImageProvider(
                                      user.photoUrl,
                                    ),
                                    child:
                                        (user.photoUrl == null ||
                                            user.photoUrl!.isEmpty)
                                        ? const Icon(
                                            Icons.person,
                                            size: 44,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                          ),
                          InkWell(
                            onTap: _isUploading ? null : _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email.isEmpty ? '-' : user.email,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Upload button if image selected
                if (_selectedImage != null)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : _uploadPhotoAndUpdateProfile,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Upload Photo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isUploading
                              ? null
                              : () => setState(() => _selectedImage = null),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                const SizedBox(height: 8),
                if (!_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => setState(() => _isEditing = true),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveName,
                              child: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _isEditing = false;
                                _nameController.text = user.name;
                              }),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                // Email Section
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email.isEmpty ? '-' : user.email,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Current Group Balance Section
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Group Balance',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      if (currentGroup == null)
                        const Text(
                          'No active group',
                          style: TextStyle(fontSize: 14),
                        )
                      else ...[
                        Text(
                          currentGroup.groupName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FutureBuilder<Map<String, double>>(
                          future: FirebaseService.getGroupBalances(
                            currentGroup.groupId,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            final userBalance =
                                (snapshot.data?[user.userId] ?? 0.0);
                            final isPositive = userBalance >= 0;
                            final balanceText =
                                '${isPositive ? '+' : ''}${userBalance.toStringAsFixed(2)}';

                            return Text(
                              balanceText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Member Since
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member Since',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Logout Button
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 4),
    );
  }
}
