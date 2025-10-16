import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/state/connectivity.dart';
import 'package:pay_app/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class OfflineBanner extends StatefulWidget {
  final String? communityUrl;

  const OfflineBanner({
    super.key,
    this.communityUrl,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;

  bool _display = false;
  ConnectivityStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _opacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _opacityController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _opacityController.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    if (_display) return;

    // Set display to true immediately
    setState(() {
      _display = true;
    });

    // Wait 50ms before animating
    await Future.delayed(const Duration(milliseconds: 50));

    // Trigger heavy haptic feedback
    HapticFeedback.heavyImpact();

    // Animate opacity to 1
    await _opacityController.forward();
  }

  Future<void> _hide() async {
    if (!_display) return;

    // Animate opacity to 0
    await _opacityController.reverse();

    // Wait 250ms
    await Future.delayed(const Duration(milliseconds: 250));

    // Trigger light haptic feedback
    HapticFeedback.lightImpact();

    // Set display to false
    setState(() {
      _display = false;
    });
  }

  void _handleStatusChange(ConnectivityStatus status) {
    if (_previousStatus == status) return;

    final shouldShow = status != ConnectivityStatus.online;

    if (shouldShow && !_display) {
      _show();
    } else if (!shouldShow && _display) {
      _hide();
    }

    _previousStatus = status;
  }

  Future<void> _openCommunityUrl() async {
    if (widget.communityUrl == null) return;

    final uri = Uri.parse(widget.communityUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select<ConnectivityState, ConnectivityStatus>(
      (state) => state.status,
    );

    // Handle status changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStatusChange(status);
    });

    if (!_display) {
      return const SizedBox.shrink();
    }

    final isConnecting = status == ConnectivityStatus.connecting;
    final backgroundColor = isConnecting ? primaryColor : dangerColor;
    final text = isConnecting ? 'Connecting...' : 'Network not available';

    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isConnecting) ...[
                  const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                    radius: 10,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isConnecting && widget.communityUrl != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openCommunityUrl,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.info_circle,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
