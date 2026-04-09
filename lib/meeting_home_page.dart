import 'package:flutter/material.dart';

import 'meeting_form_tab.dart';
import 'meeting_service.dart';
import 'meeting_voice_tab.dart';

class MeetingHomePage extends StatefulWidget {
  const MeetingHomePage({super.key});

  @override
  State<MeetingHomePage> createState() => _MeetingHomePageState();
}

class _MeetingHomePageState extends State<MeetingHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final MeetingService _service = MeetingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de reuniones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_calendar), text: 'Formulario'),
            Tab(icon: Icon(Icons.mic), text: 'Voz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MeetingFormTab(service: _service),
          MeetingVoiceTab(service: _service),
        ],
      ),
    );
  }
}
