import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../services/catbox_uploader.dart';
import 'appearance_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _avatarController = TextEditingController();
  final CatboxUploader _catboxUploader = CatboxUploader();

  bool _isSaving = false;
  bool _initialized = false;
  bool _uploadingAvatar = false;
  double? _uploadProgress;
  static const int _maxAvatarSizeBytes = 4 * 1024 * 1024; // 4MB

  @override
  void initState() {
    super.initState();
    _avatarController.addListener(_onAvatarFieldChanged);
  }

  void _onAvatarFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final client = Provider.of<ApiClient>(context);
    final user = client.user;
    if (user == null) return;

    _displayNameController.text =
        (user['displayName'] as String?) ?? (user['name'] as String?) ?? '';
    _personalEmailController.text = (user['personal_email'] as String?) ??
        (user['personalEmail'] as String?) ??
        '';
    _avatarController.text =
        (user['avatarUrl'] as String?) ?? (user['avatar_url'] as String?) ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _personalEmailController.dispose();
    _avatarController.removeListener(_onAvatarFieldChanged);
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiClient>(
      builder: (context, client, _) {
        final user = client.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final email = user['email'] as String? ?? '—';
        final username = user['username'] as String? ?? '—';
        final avatarRaw = _currentAvatarRaw(user);
        final avatarUrl = _resolveAvatarUrl(client.baseUrl, avatarRaw);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _ProfileOverviewCard(
                    email: email,
                    username: username,
                    avatarUrl: avatarUrl,
                    initials: _initials(user),
                    uploading: _uploadingAvatar,
                    uploadProgress: _uploadProgress,
                    onUpload: _uploadingAvatar ? null : _pickAndUploadAvatar,
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Appearance'),
                    subtitle: const Text('Theme & colors'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AppearanceScreen(),
                        ),
                      );
                    },
                    tileColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Complete your profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _displayNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      hintText: 'Jane Doe',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _personalEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Recovery email',
                      hintText: 'you@personalmail.com',
                      prefixIcon: Icon(Icons.alternate_email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a recovery email';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _avatarController,
                    decoration: const InputDecoration(
                      labelText: 'Avatar URL',
                      hintText: 'https://…/avatar.png',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : () => _handleSave(context),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving…' : 'Save changes'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final client = Provider.of<ApiClient>(context, listen: false);
    final success = await client.updateProfile(
      displayName: _displayNameController.text.trim(),
      personalEmail: _personalEmailController.text.trim(),
      avatarUrl: _avatarController.text.trim().isEmpty
          ? null
          : _avatarController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profile updated' : 'Failed to save profile',
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final path = file.path;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read selected file')),
      );
      return;
    }
    if (file.size > _maxAvatarSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an image under 4MB')),
      );
      return;
    }

    setState(() {
      _uploadingAvatar = true;
      _uploadProgress = 0;
    });

    try {
      final url = await _catboxUploader.uploadFile(
        path,
        filename: file.name,
        onProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      final client = Provider.of<ApiClient>(context, listen: false);
      final success = await client.updateProfile(avatarUrl: url);
      if (success) {
        setState(() {
          _avatarController.text = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated')),
          );
        }
      } else {
        throw Exception('Failed to save avatar');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar upload failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
          _uploadProgress = null;
        });
      }
    }
  }

  String? _currentAvatarRaw(Map<String, dynamic>? user) {
    if (_avatarController.text.trim().isNotEmpty) {
      return _avatarController.text.trim();
    }
    return (user?['avatarUrl'] as String?) ?? (user?['avatar_url'] as String?);
  }

  String _initials(Map<String, dynamic>? user) {
    final name = (user?['displayName'] as String?) ??
        (user?['name'] as String?) ??
        (user?['username'] as String?) ??
        '';
    if (name.trim().isEmpty) {
      final email = user?['email'] as String? ?? 'U';
      return email.substring(0, 1).toUpperCase();
    }
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({
    required this.email,
    required this.username,
    required this.initials,
    this.avatarUrl,
    required this.uploading,
    required this.onUpload,
    this.uploadProgress,
  });

  final String email;
  final String username;
  final String initials;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onUpload;
  final double? uploadProgress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colors.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarPreview(
                initials: initials,
                imageUrl: avatarUrl,
                uploading: uploading,
                progress: uploadProgress,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Username: $username',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: uploading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: uploadProgress,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(uploading ? 'Uploading photo…' : 'Upload new photo'),
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    this.imageUrl,
    required this.initials,
    required this.uploading,
    this.progress,
  });

  final String? imageUrl;
  final String initials;
  final bool uploading;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = CircleAvatar(
      radius: 36,
      backgroundColor: colors.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final avatar = (imageUrl == null || imageUrl!.isEmpty)
        ? placeholder
        : ClipRRect(
            borderRadius: BorderRadius.circular(44),
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              placeholder: (context, url) => placeholder,
              errorWidget: (context, url, error) => placeholder,
            ),
          );

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: avatar,
          ),
          if (uploading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(44),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      value: progress,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colors.secondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress != null
                        ? '${(progress! * 100).clamp(0, 100).toStringAsFixed(0)}%'
                        : 'Uploading',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String? _resolveAvatarUrl(String? baseUrl, String? avatarPath) {
  if (avatarPath == null || avatarPath.trim().isEmpty) return null;
  final trimmed = avatarPath.trim();
  if (trimmed.startsWith('http')) {
    return trimmed;
  }
  if (baseUrl == null || baseUrl.isEmpty) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '$baseUrl$trimmed';
  }
  return '$baseUrl/$trimmed';
}
