import 'package:flutter/material.dart';

import 'meeting_home_page.dart';
import 'theme/app_theme.dart';

class MeetingAssistantApp extends StatelessWidget {
  const MeetingAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meeting Assistant',
      theme: AppTheme.light(),
      home: const MeetingHomePage(),
    );
  }
}
