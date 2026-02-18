import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/memory_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final MemoryStore _memoryStore = MemoryStore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _avatarBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _memoryStore.getProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _nameController.text = profile['name'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _avatarBase64 = profile['avatar_base64'];
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _avatarBase64 = base64Encode(bytes);
    });
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    await _memoryStore.upsertProfileField('name', _nameController.text);
    await _memoryStore.upsertProfileField('bio', _bioController.text);
    await _memoryStore.upsertProfileField(
      'avatar_base64',
      _avatarBase64 ?? '',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop(true);
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _avatarBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _avatarBase64 == null || _avatarBase64!.isEmpty
        ? null
        : MemoryImage(base64Decode(_avatarBase64!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFEFE7E4),
                  backgroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF35D9C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_avatarBase64 != null && _avatarBase64!.isNotEmpty)
            TextButton.icon(
              onPressed: _removeAvatar,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus avatar'),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nama',
              filled: true,
              fillColor: Colors.white.withOpacity(0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Bio singkat',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              hintText: 'Ceritakan hobi atau hal favorit kamu',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFF35D9C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan'),
          ),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Catatan: Avatar tersimpan di memori browser saat ini.',
                style: TextStyle(color: Color(0xFF6B6460)),
              ),
            ),
        ],
      ),
    );
  }
}
