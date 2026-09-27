import 'package:flutter/material.dart';

import '../../../app/widgets/study_widgets.dart';

Future<String?> showAddSubjectDialog(
  BuildContext context, {
  required String title,
}) => showNameDialog(context, title: title, hint: 'Subject name');
