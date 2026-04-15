import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/app_logo.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({
    super.key,
    required this.member,
    required this.balance,
    this.groupName,
  });

  final User member;
  final double balance;
  final String? groupName;

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  ImageProvider? _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    if (!photoUrl.startsWith('http')) {
      try {
        return MemoryImage(base64Decode(photoUrl));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.balance >= 0;

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Member Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 58,
              backgroundImage: _getImageProvider(widget.member.photoUrl),
              child:
                  (widget.member.photoUrl == null ||
                      widget.member.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 64)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.member.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              widget.member.email.isEmpty ? '-' : widget.member.email,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            if (widget.groupName != null)
              Card(
                child: ListTile(
                  title: const Text('Group'),
                  subtitle: Text(widget.groupName!),
                ),
              ),
            Card(
              child: ListTile(
                title: const Text('Current Balance'),
                subtitle: Text(
                  '${isPositive ? '+' : ''}${widget.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('User ID'),
                subtitle: Text(widget.member.userId),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Member Since'),
                subtitle: Text(
                  '${widget.member.createdAt.day}/${widget.member.createdAt.month}/${widget.member.createdAt.year}',
                ),
              ),
            ),
            if (widget.member.isGroupAdmin)
              const Card(
                child: ListTile(title: Text('Role'), subtitle: Text('Admin')),
              ),
          ],
        ),
      ),
    );
  }
}
