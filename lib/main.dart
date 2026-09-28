import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/ads_service.dart';
import 'services/interaction_feedback.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(InteractionFeedback.initialize());
  unawaited(AdsService.instance.initialize());
  runApp(const RivioApp());
}
