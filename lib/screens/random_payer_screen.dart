import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/group_provider.dart';
import '../services/member_service.dart';
import '../widgets/app_logo.dart';

class RandomPayerScreen extends StatefulWidget {
  const RandomPayerScreen({super.key});

  @override
  State<RandomPayerScreen> createState() => _RandomPayerScreenState();
}

class _RandomPayerScreenState extends State<RandomPayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentRotation = 0;

  List<User> _members = [];
  final Set<String> _selectedMemberIds = <String>{};
  bool _isLoading = true;
  bool _isSpinning = false;
  int _winnerIndex = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this);
    _spinAnimation = const AlwaysStoppedAnimation<double>(0);
    _loadMembers();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final group = context.read<GroupProvider>().currentGroup;
    if (group == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final members = await MemberService.getGroupMembers(group.groupId);
    if (!mounted) return;

    setState(() {
      _members = members;
      _selectedMemberIds
        ..clear()
        ..addAll(members.map((e) => e.userId));
      _isLoading = false;
      _winnerIndex = 0;
    });
  }

  List<User> get _selectedMembers {
    return _members
        .where((m) => _selectedMemberIds.contains(m.userId))
        .toList();
  }

  Color _segmentColor(int index) {
    final palette = <Color>[
      const Color(0xFFFF6B6B),
      const Color(0xFFFFA94D),
      const Color(0xFFFFD43B),
      const Color(0xFF69DB7C),
      const Color(0xFF4DABF7),
      const Color(0xFF9775FA),
      const Color(0xFFF06595),
      const Color(0xFF20C997),
    ];
    return palette[index % palette.length];
  }

  Future<void> _spinWheel() async {
    final participants = _selectedMembers;
    if (_isSpinning || participants.length < 2) return;

    final random = math.Random();
    final sweep = (2 * math.pi) / participants.length;
    final extraRounds = 6 + random.nextInt(5);
    final spinOffset = random.nextDouble() * (2 * math.pi);
    final targetRotation =
        _currentRotation + (extraRounds * 2 * math.pi) + spinOffset;
    final durationSeconds = 2 + random.nextInt(4);

    _spinController
      ..stop()
      ..reset()
      ..duration = Duration(seconds: durationSeconds);

    _spinAnimation = Tween<double>(begin: 0, end: targetRotation).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    setState(() {
      _isSpinning = true;
      _winnerIndex = 0;
    });

    await _spinController.forward();
    _currentRotation = targetRotation % (2 * math.pi);

    if (!mounted) return;
    setState(() {
      final pointerAngle = (-math.pi / 2 - _currentRotation) % (2 * math.pi);
      final normalized = (pointerAngle + 2 * math.pi) % (2 * math.pi);
      final computedIndex =
          (normalized ~/ sweep) %
          (participants.isEmpty ? 1 : participants.length);
      _winnerIndex = computedIndex;
      _isSpinning = false;
    });

    final winner = participants[_winnerIndex];
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('${winner.name} is the random payer!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participants = _selectedMembers;
    final canSpin = participants.length >= 2;

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Random Payer'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? const Center(child: Text('No members found in this group'))
          : Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -32,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.arrow_drop_down,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _spinAnimation,
                          builder: (context, _) {
                            return Transform.rotate(
                              angle: _spinAnimation.value,
                              child: CustomPaint(
                                size: const Size(280, 280),
                                painter: _WheelPainter(
                                  members: participants,
                                  colorForIndex: _segmentColor,
                                ),
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: canSpin && !_isSpinning ? _spinWheel : null,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _isSpinning ? '...' : 'SPIN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    canSpin
                        ? 'Tap spin button to pick a payer'
                        : 'Select at least 2 members to spin',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: canSpin
                          ? Theme.of(context).colorScheme.primary
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final selected = _selectedMemberIds.contains(
                              member.userId,
                            );
                            return CheckboxListTile(
                              dense: true,
                              value: selected,
                              title: Text(member.name),
                              onChanged: _isSpinning
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedMemberIds.add(member.userId);
                                        } else {
                                          _selectedMemberIds.remove(
                                            member.userId,
                                          );
                                        }
                                      });
                                    },
                            );
                          },
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

class _WheelPainter extends CustomPainter {
  final List<User> members;
  final Color Function(int index) colorForIndex;

  _WheelPainter({required this.members, required this.colorForIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    if (members.isEmpty) {
      paint.color = Colors.grey.shade300;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final sweep = (2 * math.pi) / members.length;

    for (var i = 0; i < members.length; i++) {
      paint.color = colorForIndex(i);
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );

      final textAngle = start + (sweep / 2);
      final textOffset = Offset(
        center.dx + math.cos(textAngle) * (radius * 0.62),
        center.dy + math.sin(textAngle) * (radius * 0.62),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: members[i].name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black38, blurRadius: 2)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: radius * 0.7);

      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(textAngle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.members != members;
  }
}
