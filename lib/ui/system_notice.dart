import 'dart:async';
import 'package:flutter/material.dart';
import '../core/market/market_strings.dart';
import '../core/theme.dart';
import 'liquid_surface.dart';

/// Keeps system banners inside the phone and above the current application.
class SystemNoticeHost extends StatefulWidget {
  final Widget child;
  final double topInset;
  const SystemNoticeHost({super.key, required this.child, this.topInset = 58});
  static SystemNoticeHostState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NoticeScope>()?.state;
  @override
  State<SystemNoticeHost> createState() => SystemNoticeHostState();
}

class SystemNoticeHostState extends State<SystemNoticeHost> {
  Timer? _timer;
  String? _message;
  int _sequence = 0;
  void show(String message) {
    _timer?.cancel();
    setState(() {
      _message = message;
      _sequence++;
    });
    _timer = Timer(Duration(seconds: message.length > 110 ? 7 : 5), dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    if (mounted) setState(() => _message = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shownSequence = _sequence;
    return _NoticeScope(
      state: this,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned(
            top: MediaQuery.paddingOf(context).top + widget.topInset,
            left: 10,
            right: 10,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder:
                      (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -.25),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                  child:
                      _message == null
                          ? const SizedBox.shrink()
                          : Dismissible(
                            key: ValueKey(_sequence),
                            direction: DismissDirection.up,
                            onDismissed: (_) {
                              if (shownSequence == _sequence) dismiss();
                            },
                            child: SystemNoticeBanner(
                              message: _message!,
                              onClose: dismiss,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeScope extends InheritedWidget {
  final SystemNoticeHostState state;
  const _NoticeScope({required this.state, required super.child});
  @override
  bool updateShouldNotify(_NoticeScope oldWidget) => state != oldWidget.state;
}

class SystemNoticeBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const SystemNoticeBanner({
    super.key,
    required this.message,
    required this.onClose,
  });
  @override
  Widget build(BuildContext context) {
    final p = IosColors.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        type: MaterialType.transparency,
        child: LiquidSurface(
          radius: 26,
          highContrast: true,
          padding: const EdgeInsets.fromLTRB(13, 12, 5, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TechLife',
                            style: TextStyle(
                              color: p.label,
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          mt('сейчас', 'now', 'зараз'),
                          style: TextStyle(
                            color: p.secondary,
                            fontFamily: 'Roboto',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .25,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          message,
                          key: const ValueKey('system_notice_text'),
                          style: TextStyle(
                            color: p.label,
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: p.secondary, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
