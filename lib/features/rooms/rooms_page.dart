import 'package:flutter/material.dart';
import '../../widgets/dv_logo.dart';
import '../../widgets/state_widgets.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DvLogo(size: 20),
      ),
      body: const DvEmptyState(
        icon: Icons.history_rounded,
        title: 'NO RECENT ROOMS',
        subtitle: 'Rooms you create or join will appear here.\n(Implementation pending)',
      ),
    );
  }
}
