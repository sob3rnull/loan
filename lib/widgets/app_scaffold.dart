import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/state/app_state_controller.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final bottomBarWidget = bottomBar;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Consumer<AppStateController>(
              builder: (context, controller, _) {
                if (!controller.isWorking) {
                  return const SizedBox.shrink();
                }
                return const LinearProgressIndicator(minHeight: 4);
              },
            ),
            Consumer<AppStateController>(
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
                      color: const Color(0xFFFFF0CC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE3AD2A)),
                    ),
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              },
            ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: bottomBarWidget == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: bottomBarWidget,
            ),
    );
  }
}
