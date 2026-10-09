import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'profile_photo_service.dart';

class ProfilePhotoAvatar extends StatefulWidget {
  final String initials;
  final double radius;
  final VoidCallback onChanged;

  const ProfilePhotoAvatar({
    super.key,
    required this.initials,
    required this.onChanged,
    this.radius = 44,
  });

  @override
  State<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends State<ProfilePhotoAvatar> {
  late Future<Uint8List?> _photo = ProfilePhotoService.load();
  bool _uploading = false;

  Future<void> _upload() async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
    });
    try {
      await ProfilePhotoService.pickAndUpload();
      if (!mounted) return;
      
      final nextPhoto = ProfilePhotoService.load();
      setState(() {
        _photo = nextPhoto;
      });
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } on ProfilePhotoException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FutureBuilder<Uint8List?>(
            future: _photo,
            builder: (context, snapshot) {
              return CircleAvatar(
                radius: widget.radius,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: snapshot.hasData && snapshot.data != null
                      ? Image.memory(
                          snapshot.data!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _Initials(
                                initials: widget.initials,
                                size: size,
                              ),
                        )
                      : _Initials(initials: widget.initials, size: size),
                ),
              );
            },
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _uploading ? null : _upload,
              child: SizedBox(
                width: 34,
                height: 34,
                child: _uploading
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  final double size;

  const _Initials({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFDBEAFE),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 26,
        ),
      ),
    );
  }
}
