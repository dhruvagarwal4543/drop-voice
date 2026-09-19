import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/errors/app_exception.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/dv_avatar.dart';
import '../../widgets/dv_text_field.dart';
import '../../widgets/gaming_buttons.dart';
import '../../widgets/telemetry_label.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  final _userService = UserService();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _auth.uid;
      final profile = await _userService.getProfile(uid);
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;

    final result = await showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile, userService: _userService),
    );

    if (result != null && mounted) {
      setState(() => _profile = result);
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final uid = _auth.uid;
      final url = await _userService.uploadAvatar(uid, File(picked.path));
      await _userService.updateProfile(uid, {'avatarUrl': url});
      final updated = _profile?.copyWith(avatarUrl: url);
      if (mounted) setState(() { _profile = updated; _isSaving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: $e'), backgroundColor: Dv.crimson),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Dv.graphite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dv.r12), side: const BorderSide(color: Dv.steel)),
        title: Text('SIGN OUT', style: Dv.headline(size: 18)),
        content: Text('Are you sure you want to sign out?', style: Dv.body(color: Dv.ash)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL', style: Dv.button(color: Dv.ash))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('SIGN OUT', style: Dv.button(color: Dv.crimson))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Dv.obsidian, body: Center(child: CircularProgressIndicator(color: Dv.green)));
    }

    final profile = _profile;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Dv.obsidian,
      appBar: AppBar(
        title: Text('GAMING IDENTITY', style: Dv.mono(color: Dv.white, size: 14)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Dv.ash, size: 20),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dv.s24),
        child: Column(
          children: [
            const SizedBox(height: Dv.s16),

            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                DvAvatar(
                  name: profile?.displayName ?? 'Player',
                  radius: 52,
                  showPresence: true,
                  isOnline: true,
                  imageUrl: profile?.avatarUrl,
                ),
                GestureDetector(
                  onTap: _isSaving ? null : _changeAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Dv.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Dv.obsidian, width: 2),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Dv.obsidian))
                        : const Icon(Icons.camera_alt_rounded, size: 14, color: Dv.obsidian),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Dv.s20),

            // Name
            Text(
              profile?.displayName ?? user?.displayName ?? 'PLAYER',
              style: Dv.headline(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dv.s4),
            Text(
              '@${profile?.username ?? 'unknown'}',
              style: Dv.mono(size: 13, color: Dv.green),
            ),

            const SizedBox(height: Dv.s8),

            // Status badge
            _StatusBadge(status: profile?.status ?? UserStatus.offline),

            const SizedBox(height: Dv.s32),

            // Info cards
            if (profile?.bio != null && profile!.bio!.isNotEmpty)
              _InfoCard(icon: Icons.info_outline_rounded, label: 'BIO', value: profile.bio!),

            if (profile?.gamingId != null && profile!.gamingId!.isNotEmpty)
              _InfoCard(icon: Icons.sports_esports_rounded, label: 'GAMING ID', value: profile.gamingId!),

            if (profile?.favouriteGame != null && profile!.favouriteGame!.isNotEmpty)
              _InfoCard(icon: Icons.star_rounded, label: 'FAVOURITE GAME', value: profile.favouriteGame!),

            _InfoCard(
              icon: Icons.shield_outlined,
              label: 'ACCOUNT',
              value: user?.email ?? 'Google Account',
            ),

            const SizedBox(height: Dv.s32),

            // Edit button
            PrimaryButton(
              label: 'EDIT PROFILE',
              icon: Icons.edit_rounded,
              onPressed: _editProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      UserStatus.online => ('ONLINE', Dv.green),
      UserStatus.inRoom => ('IN ROOM', Colors.amber),
      UserStatus.offline => ('OFFLINE', Dv.ash),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dv.s12, vertical: Dv.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dv.r8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: Dv.s8),
          Text(label, style: Dv.mono(size: 11, color: color)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dv.s12),
      padding: const EdgeInsets.all(Dv.s16),
      decoration: BoxDecoration(
        color: Dv.graphite,
        borderRadius: BorderRadius.circular(Dv.r12),
        border: Border.all(color: Dv.steel),
      ),
      child: Row(
        children: [
          Icon(icon, color: Dv.ash, size: 18),
          const SizedBox(width: Dv.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TelemetryLabel(text: label, color: Dv.ash),
                const SizedBox(height: Dv.s4),
                Text(value, style: Dv.body(color: Dv.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Edit Profile Bottom Sheet
// ──────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.userService});
  final UserProfile profile;
  final UserService userService;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _gamingIdCtrl;
  late final TextEditingController _favouriteGameCtrl;

  bool _isSaving = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.displayName);
    _usernameCtrl = TextEditingController(text: p.username);
    _bioCtrl = TextEditingController(text: p.bio ?? '');
    _gamingIdCtrl = TextEditingController(text: p.gamingId ?? '');
    _favouriteGameCtrl = TextEditingController(text: p.favouriteGame ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose(); _bioCtrl.dispose();
    _gamingIdCtrl.dispose(); _favouriteGameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();

    // Validate username
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      setState(() => _usernameError = '3-20 chars, letters, numbers, underscores only');
      return;
    }

    setState(() { _isSaving = true; _usernameError = null; });

    try {
      // Check uniqueness if changed
      if (username.toLowerCase() != widget.profile.usernameLowercase) {
        final available = await widget.userService.isUsernameAvailable(username, excludeUid: widget.profile.uid);
        if (!available) {
          if (mounted) setState(() { _isSaving = false; _usernameError = 'Username taken. Choose another.'; });
          return;
        }
      }

      await widget.userService.updateProfile(widget.profile.uid, {
        'displayName': _nameCtrl.text.trim(),
        'username': username,
        'bio': _bioCtrl.text.trim(),
        'gamingId': _gamingIdCtrl.text.trim(),
        'favouriteGame': _favouriteGameCtrl.text.trim(),
      });

      final updated = widget.profile.copyWith(
        displayName: _nameCtrl.text.trim(),
        username: username,
        bio: _bioCtrl.text.trim(),
        gamingId: _gamingIdCtrl.text.trim(),
        favouriteGame: _favouriteGameCtrl.text.trim(),
      );

      if (mounted) Navigator.pop(context, updated);
    } on FirestoreException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Dv.crimson),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Dv.graphite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: Dv.s24, right: Dv.s24, top: Dv.s24,
        bottom: MediaQuery.of(context).viewInsets.bottom + Dv.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Dv.steel, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: Dv.s20),
            Text('EDIT PROFILE', style: Dv.headline(size: 18)),
            const SizedBox(height: Dv.s20),
            DvTextField(controller: _nameCtrl, labelText: 'DISPLAY NAME', hintText: 'Your name'),
            const SizedBox(height: Dv.s16),
            DvTextField(
              controller: _usernameCtrl, labelText: 'USERNAME', hintText: 'your_username',
              errorText: _usernameError,
            ),
            const SizedBox(height: Dv.s16),
            DvTextField(controller: _bioCtrl, labelText: 'BIO', hintText: 'Tell your squad about you', maxLength: 150),
            const SizedBox(height: Dv.s16),
            DvTextField(controller: _gamingIdCtrl, labelText: 'GAMING ID', hintText: 'BGMI / COD ID'),
            const SizedBox(height: Dv.s16),
            DvTextField(controller: _favouriteGameCtrl, labelText: 'FAVOURITE GAME', hintText: 'BGMI, Valorant...'),
            const SizedBox(height: Dv.s24),
            PrimaryButton(label: 'SAVE', icon: Icons.check_rounded, onPressed: _isSaving ? null : _save, isLoading: _isSaving),
          ],
        ),
      ),
    );
  }
}
