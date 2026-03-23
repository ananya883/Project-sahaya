import 'package:flutter/material.dart';

class TopAlertNotification extends StatefulWidget {
  final int activeAlertCount;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const TopAlertNotification({
    super.key,
    required this.activeAlertCount,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<TopAlertNotification> createState() => _TopAlertNotificationState();
}

class _TopAlertNotificationState extends State<TopAlertNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAlert = widget.activeAlertCount > 0;
    
    final gradientColors = hasAlert
        ? [Colors.red.shade50, Colors.white]
        : [Colors.green.shade50, Colors.white];
    
    final borderColor = hasAlert ? Colors.red.shade200 : Colors.green.shade200;
    final iconBgColor = hasAlert ? Colors.red.shade100 : Colors.green.shade100;
    final mainColor = hasAlert ? Colors.red : Colors.green;
    final dismissBgColor = hasAlert ? Colors.red.shade100 : Colors.green.shade100;
    final shadowColor = hasAlert ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: const Key('alert_notification'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => widget.onDismiss(),
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dismissBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Icon(Icons.close, color: mainColor, size: 28),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dismissBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.close, color: mainColor, size: 28),
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                      hasAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: mainColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAlert ? "🚨 Disaster Alert!" : "✅ Weather Safe!",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasAlert 
                              ? "You have ${widget.activeAlertCount} active disaster warning(s). Tap here to view details." 
                              : "No active disaster risks in your subscribed locations.",
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
