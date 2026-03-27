import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.bottomBar,
    this.actions,
  });

  final String title;
  final Widget child;
  final Widget? bottomBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Consumer<AppController>(
              builder: (context, controller, _) {
                if (controller.isWorking) {
                  return const LinearProgressIndicator(minHeight: 4);
                }
                return const SizedBox.shrink();
              },
            ),
            Consumer<AppController>(
              builder: (context, controller, _) {
                final message = controller.editBlockedMessage;
                if (message == null) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2CC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5B048)),
                    ),
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              },
            ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: bottomBar,
            ),
    );
  }
}

