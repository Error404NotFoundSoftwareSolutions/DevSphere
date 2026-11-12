// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-UX-001..007
// Implemented here: keyboard navigation focus helpers

import 'package:flutter/material.dart';

void requestAccessibleFocus(BuildContext context, FocusNode node) {
  FocusScope.of(context).requestFocus(node);
}
